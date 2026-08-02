# Phober — Complete Project Context

## Overview

**Phober** is a VR gaming hall management system. Staff manage sessions on VR devices, handle billing (invoices), and track employees. Backend microservices are fronted by a single API gateway; a React staff dashboard and a static marketing website consume it; VR device overlays receive live schedule updates over a WebSocket channel.

**Stack:** Laravel 11, PHP 8.2, Apache, MySQL 8, Redis, Docker, Reverb (WebSockets), MinIO (S3), OpenTelemetry (tracing), ELK (logging).

There is **no desktop-overlay project in this monorepo**. Whatever runs on the VR device screen is an external client — device-service exposes a dedicated MAC-address-scoped, secret-protected endpoint and broadcast channel for it (see `Overlay Feature` under device-service). Treat any reference to a bundled WPF/C# overlay app as historical/aspirational, not current code.

---

## Microservices

| Container | Path | DB Queue | Purpose |
|---|---|---|---|
| `staff-service` | `services/staff-service` | `staff` | Sessions, employees, invoices, snacks, TV pin display |
| `device-service` | `services/device-service` | `device` | VR device instances, schedules, games, tariffs, overlay feed |
| `adminpanel` | `services/adminpanel` | `adminpanel` | Admin panel |
| `auth-server` | `services/auth-server` | `auth` | Authentication |
| `config-server` | `services/config-server` | `config` | Runtime configuration |
| `notification-server` | `services/notification-server` | `notification` | Notifications (Discord/Telegram) |
| `crm-service` | `services/crm-service` | `crm` | CRM (customers, loyalty) |

All seven of the above are Laravel/PHP services and git submodules (see `.gitmodules`), sharing `shared/laravel-common`.

### Non-Laravel projects (also git submodules, not proxied through the API gateway)

| Project | Path | Stack | Purpose |
|---|---|---|---|
| `staff-app` | `services/staff-app` | React 18 + TypeScript + Vite + Tailwind 4 | Staff-facing dashboard. Talks to the gateway (`/auth/`, `/crm/`, `/hardware/`, `/staff/`) via `src/api/*`, and to Reverb via `laravel-echo`/`pusher-js` (`src/realtime/echo.ts`). Pages: Home, Sessions, Bar (snacks), Customers, Invoices, Tariffs, TV, Login. Served in dev by a Node 20 container running `npm run dev`; CORS-whitelisted at the gateway as `https://staff.phober.test`. |
| `website` | `services/website` | Static HTML/CSS/JS (jQuery-era vendor libs) | Public marketing site for the VR hall. Served by its own `nginx:alpine` container, not routed through the API gateway. |

---

## API Gateway

Nginx: `docker/api-gateway/nginx.conf`. Single entrypoint: `api.phober.test`.

| URL prefix | Upstream | Notes |
|---|---|---|
| `/staff/` | `staff-service:80` | |
| `/hardware/` | `device-service:80` | |
| `/auth/` | `auth-server:80` | |
| `/crm/` | `crm-service:80` | |
| `/configs/` | `config-server:80` | |
| `/ws/` | `ws:8080` (Reverb) | rewrites `/ws(/.*)$` → `$1`, sets upgrade headers |
| `/s3/` | `minio:9000` | |
| `/notification/` | `notification-server:80` | **commented out / disabled** |
| `/webhook/` | `notification-server:80/webhook/` | Discord/Telegram webhook ranges also commented out |
| `/.well-known/` | static files (`/etc/nginx/public`) | ACME challenge |
| `/test` | — | returns `200 'Test'`, health-check stub |

CORS (`map $http_origin`) whitelists `https://staff.phober.test` and `https://ws.phober.test`. `staff-app` and `website` are **not** proxied through this gateway — they're served directly by their own containers (`docker-compose.frontend.yml`).

---

## Shared Package: `laravel-common`

Path: `shared/laravel-common/`. **This is not a real installable Composer package** — its `composer.json` was deleted (commit `bd8bc75`, 2026-07-25). Each service instead declares a path-based PSR-4 autoload entry directly in its own `composer.json`:
```
"psr-4": { "Phobiavr\\PhoberLaravelCommon\\": "shared/laravel-common/src/" }
```
Namespace: `Phobiavr\PhoberLaravelCommon`. Models live directly under `src/` (no `Models/` subdirectory).

### Jobs
- `Jobs/HandleSessionSchedule` — queued job (`ShouldQueue`) that syncs session state to device-service. Constructor: `int $instanceId`, `SessionScheduleActionEnum $action`, `?int $time = null`, `?int $sessionId = null`, `?string $startedAt = null`. Captures W3C trace headers at dispatch time (`Tracer::currentTraceHeaders()`) and re-wraps `handle()` in a CONSUMER span (`Tracer::withConsumerSpan`, force-flushed after — needed since `queue:work` never hits PHP's normal request-shutdown flush). `handle(SessionScheduleHandlerInterface $handler)` just delegates to the injected handler.

### Contracts
- `Contracts/SessionScheduleHandlerInterface::handle(int $instanceId, SessionScheduleActionEnum $action, ?int $time, ?int $sessionId, ?string $startedAt = null): void` — implemented by `SessionScheduleHandler` in device-service, bound via `DependencyInjectionServiceProvider`.
- `Contracts/AuthUserInterface` — `FIELD_ID/USERNAME/FIRST_NAME/LAST_NAME/EMAIL/PERMISSIONS` constants; getters for each plus `hasPermission(string): bool`. Implemented by `Data/AuthUser`.

### HTTP Clients
All clients route through `src/Http/Http.php`, a drop-in static proxy for Laravel's `Http` facade (not the raw facade) — every call gets: `Tracer::httpMiddleware()` (CLIENT span + trace-header injection), `acceptJson()`, `timeout(5)`, `connectTimeout(3)`, `retry(2, backoff 100ms/attempt, only on ConnectionException)`, header `X-Service-Secret: config('service.secret')`. `ConnectionException` is converted to `ServiceUnavailableException`. (`AuthClient::login()` is the one exception — it calls the raw `Http` facade directly so it can forward the caller's bearer token.)

| Client | Base URL | Methods |
|---|---|---|
| `DeviceClient` | `http://device-service` | `schedule(SchedulePayload $payload)` → POST `/schedule`; `deleteSchedule(int $id)` → DELETE `/schedule/{id}`; `price(PricePayload $payload)` → POST `/price` |
| `StaffClient` | `http://staff-service` | `sessionById(int $sessionId)` → GET `/sessions/{sessionId}` |
| `CrmClient` | `http://crm-service` | `customer(int $customerId)` → GET `/customers/{customerId}` |
| `AuthClient` | `http://auth-server` | `login(): ?AuthUser` → GET `/valid` with the forwarded bearer token; `user(?int $id): ?AuthUser` → GET `/users/{id}`, memoized per-process; `linkTelegram(array $params): bool` → POST `/link/telegram` |
| `ConfigClient` | `http://config-server` | `update(bool $dryRun)` → GET `/`, rewrites `.env.shared` with returned key/values (adds new keys, optionally overwrites via `overwriteExistingValues()`, deletes stale keys); `runEveryTime()` flags `SharedServiceProvider::boot()` to call `update(false)` on every boot |
| `NotificationClient` | `env('NOTIFICATION_SERVER_URL', 'http://notification-server')` | `sendMessage(NotificationProvider, NotificationChannel, string $message)` → POST `/`; `generateShortLinkForTelegram(array $payload)` — pure helper (no HTTP), builds a `t.me/phober_bot?start=...` deep link |
| `OtpClient` | `http://auth-server/otp` | `generateOtp(): self` (static) → POST `/generate`; `validate(string $identifier, ?string $code = null): bool` (static) → POST `/validate` or `/check-submitted` |

### Traits
- `Traits/Authorable` — `bootAuthorable()`: on `created`, if `Auth::check()`, creates an `Author` row (`created_by` + `last_updated_by` = `Auth::id()`); on `updated`, if `Auth::check()`, updates `last_updated_by`. Guest-created records get no `Author` row. Relation: `author(): MorphOne(Author::class, 'authorable')`.
- `Traits/AuthUserArrayable` — `toAuthUserArray(): array`, maps `AuthUserInterface` getters to its `FIELD_*` constant keys.

### Models (directly under `src/`, no `Models/` subdirectory)
- `Author` — connection `db_shared`. Fillable: `created_by`, `last_updated_by`, `updated_at`. Relation: `authorable(): MorphTo`. Appends: `authorable_created_at`/`authorable_updated_at` (proxy to `$this->authorable->created_at`/`updated_at`). Accessors `created_by`/`updated_by` resolve to a full `AuthUser` via `AuthClient::user($id)`.
- `Hostname` — connection `db_shared`. Fillable: `hostname`, `container`.
- `IdempotencyKey` — connection `db_shared`. Fillable: `scope`, `key`, `request_hash`, `response_status`, `response_content_type`, `response_body`. `isPending(): bool` → `response_status` is null.
- `Media` — connection `db_shared`, extends Spatie `MediaCollections\Models\Media`.
- `JsonGuard` — not an Eloquent model; implements `Illuminate\Contracts\Auth\Guard`. `validate()` always returns `false` — the user is never authenticated from local credentials, only set externally via `setUser()` after `AuthServerMiddleware` validates the bearer token against auth-server. Registered as the `json` Auth guard driver.

### Enums (16 total, `src/Enums/`)
| Enum | Values |
|---|---|
| `SessionStatusEnum` | `QUEUE`, `ACTIVE`, `CANCELED`, `FINISHED` |
| `SessionTimeEnum` | `MIN_15`, `MIN_30`, `MIN_60` — `getMins(): int` returns 15/30/60 |
| `SessionTariffEnum` | `MORNING`, `EVENING`, `EXTRA` |
| `SessionScheduleActionEnum` | `QUEUE = 'queue'`, `START = 'start'`, `CANCEL = 'cancel'`, `FINISH = 'finish'` (lowercase-valued, unlike the others) |
| `ScheduleEnum` | `MAINTENANCE`, `RESERVATION`, `INSPECTION`, `REPAIR`, `IN_USE`, `IN_SESSION`, `QUEUE`, `ON_EVENT`, `CANCELED` |
| `InvoiceStatusEnum` | `QUEUE`, `PAYED`, `CANCELED` |
| `InvoicePaymentMethodEnum` | `CASH`, `CARD`, `BONUS` |
| `ReservationStatusEnum` | `QUEUE`, `CANCELED`, `APPROVED` |
| `ReservationRequestEnum` | `WEBSITE`, `STAFF_APP` |
| `LoyaltyCardStatusEnum` | `BASIC`, `SILVER`, `GOLD`, `PLATINUM` |
| `CustomerStatusEnum` | `PENDING`, `APPROVED`, `VIP`, `BLACKLIST` |
| `GenderEnum` | `MALE = 'M'`, `FEMALE = 'F'` |
| `ContactTypeEnum` | `PHONE`, `EMAIL`, `TELEGRAM` |
| `DeviceEnum` | `HTC`, `OCULUS`, `PS_VR`, `OMNI`, `DOF_3` |
| `NotificationChannel` | `SUPPORT`, `OTP` |
| `NotificationProvider` | `DISCORD`, `TELEGRAM` |

### Middleware (`src/Middleware/`, 8 total)
| Class | Alias | What it does |
|---|---|---|
| `AuthServerMiddleware` | `auth.server` | Calls `AuthClient::login()`; on success sets the `AuthUser` on `Auth::guard('server')`; on failure throws `AuthenticationException` |
| `ForceJsonMiddleware` | — (pushed globally) | Forces `Accept: application/json` on every inbound request |
| `TranslationMiddleware` | — (pushed globally) | `App::setLocale($request->getPreferredLanguage(['en','ru','az']) ?? 'en')` |
| `TraceRequestMiddleware` | — (pushed globally, first) | Wraps the whole request in a SERVER span via `Tracer::withServerSpan()` |
| `IdempotencyMiddleware` | `idempotent` | Dedupes mutating requests carrying an `Idempotency-Key` header via the `IdempotencyKey` model; replays the stored response on retry; throws `409 ConflictHttpException` if the prior request is still pending or the payload hash differs |
| `OTPGenerateMiddleware` | `otp.generate` | Calls `OtpClient::generateOtp()`; stamps `X-OTP-Identifier` on the response |
| `OTPMiddleware` | `otp` | Reads `X-OTP-Identifier`/`X-OTP-Code` headers, validates via `OtpClient::validate()` |
| `PrivateMiddleware` | `private` | `hash_equals(config('service.secret'), $request->header('X-Service-Secret'))` |

### SharedServiceProvider (`src/SharedServiceProvider.php` — the only provider in the package)
- `register()`: `mergeConfigFrom('config/features.php', 'features')` (`rude_mode`); `mergeConfigFrom('config/service.php', 'service')` (`secret`, `overlay_secret`).
- `boot()`:
  - Registers artisan commands `UpdateHostnameCommand`, `UpdateConfigsCommand` (`src/Commands/`).
  - `loadRoutesFrom('routes/api.php')` — 3 shared routes: `GET /health`, `GET /instance-info` (`{instance_id: gethostname()}`), `GET /config-client/update` (`private` middleware, drives `config-client:update` artisan command).
  - Pushes global middleware **in this order**: `TraceRequestMiddleware`, `ForceJsonMiddleware`, `TranslationMiddleware`.
  - `Log::pushProcessor(new TraceIdProcessor())` — stamps every log line with `trace_id`/`span_id`.
  - Registers middleware aliases: `auth.server`, `otp`, `otp.generate`, `private`, `idempotent`.
  - If `ConfigClient::$runEveryTime` is set, calls `ConfigClient::update(false)` at boot.
  - `Auth::extend('json', ...)` — registers `JsonGuard`.
  - Sets `database.connections.db_shared` at runtime from `DB_SHARED_*` env vars.
  - `$this->app->useLangPath('resources/lang')` — points translations at the package's own `en/az/ru` locale files.
  - `EventServiceProvider::disableEventDiscovery()`.

### Tracing (`src/Tracing/Tracer.php`)
Thin static wrapper around the OpenTelemetry SDK; no-ops when the SDK isn't installed (`class_exists(Globals::class)`). `currentTraceHeaders()`, `currentTraceId()`/`currentSpanId()`, `withServerSpan()` (used by `TraceRequestMiddleware`), `httpMiddleware()` (Guzzle middleware used by `Http.php`), `withConsumerSpan()` (used by `HandleSessionSchedule`).

### Exceptions (`src/Exceptions/`)
- `ServiceUnavailableException` — thrown when an inter-service HTTP call can't reach its target at all (connection refused/DNS/timeout); **not** thrown for a reachable service returning non-2xx. Thrown from `AuthClient::login()` and centrally from `Http.php`. Caught in: `staff-service` (`SessionService`, `InvoiceService`), `device-service` (`ScheduleController`, `InstanceService`, `ScheduleUpdatedOverlay`).
- `ProblemJsonHandler::register(Exceptions $exceptions)` — registered from each service's `bootstrap/app.php`; renders every exception as RFC 7807 `application/problem+json`: `ValidationException`→422, `AuthenticationException`→401, `ServiceUnavailableException`→503, any `HttpExceptionInterface`→its status, else→500 (message hidden unless `app.debug`).

### DTOs (`src/Data/`)
`AuthUser` (implements `AuthUserInterface`), `PricePayload` (factories `forInstance()`/`forDevice()`), `SchedulePayload`, `SendMessagePayload`, `GenerateOtpPayload`, `ValidateOtpPayload`, `CheckSubmittedPayload` — all `readonly`, with `fromArray()`/`toArray()`.

### Other directories
- `src/Pageable/` — generic Eloquent pagination kit: `Pageable` trait (swaps in `PageableBuilder`), `PageableBuilder::paginateFromRequest()`, `PageableCollection` (outputs `{data, total, size, current_page, total_pages}`), `PageableRequest` (normalizes `size`/`columns`/`page` query params).
- `src/Logging/TraceIdProcessor.php` — Monolog processor, stamps `trace_id`/`span_id` from the active span.
- `src/Commands/` — `UpdateConfigsCommand` (`config-client:update`), `UpdateHostnameCommand` (`hostname:update {container}`, retries 5× on failure).
- `src/Testing/` — `ClearsExistingRows` (wipes given model tables at test start, safe under `DatabaseTransactions`), `FakesAuthServer` (`Http::fake()` helpers for `GET http://auth-server/valid`).

---

## Queue System

**Driver:** `database` for all services.
**Connection:** `db_shared` — shared MySQL database. Table: `jobs`.
**Each service has its own named queue** (`DB_QUEUE` env var). Jobs are written to `db_shared.jobs` with the appropriate `queue` column value.

The queue worker for each service must be started manually — Apache is the container entrypoint, no worker runs automatically inside containers. In `docker-compose.realtime.yml`, dedicated worker containers exist: `notification-queue`, `staff-queue`, `device-queue`, plus `device-schedule` (Laravel scheduler for device-service; a `staff-schedule` equivalent is defined but commented out).

`HandleSessionSchedule` is dispatched from `staff-service` to `->onQueue('device')`. It lands in `db_shared.jobs` with `queue='device'`. The `device-queue` worker picks it up and executes `SessionScheduleHandler::handle()`.

---

## staff-service

### Routes (`routes/api.php`)

All staff routes are prefixed `/staff/` at the gateway level (stripped before hitting the service). **There is no root `/` route and no `MeController` in this service.**

| Method | Path | Middleware | Controller |
|---|---|---|---|
| GET | `/otp/make` | `otp.generate` | `OtpController@make` (stub: returns literal `'make'`) |
| GET | `/otp/submit` | `otp` | `OtpController@submit` (stub: returns literal `'submit'`) |
| GET | `/employees` | `auth.server` | `EmployeeController@index` |
| GET | `/invoices` | `auth.server` | `InvoiceController@index` |
| PUT | `/invoices/{id}` | `auth.server` | `InvoiceController@pay` |
| DELETE | `/invoices/{id}` | `auth.server` | `InvoiceController@cancel` |
| GET | `/sessions/today` | `auth.server` | `SessionController@today` |
| GET | `/sessions` | `auth.server` | `SessionController@active` |
| POST | `/sessions` | `auth.server`, `idempotent` | `SessionController@store` |
| DELETE | `/sessions/{id}` | `auth.server` | `SessionController@cancel` |
| PUT | `/sessions/{id}/start` | `auth.server` | `SessionController@start` |
| PUT | `/sessions/{id}/finish` | `auth.server` | `SessionController@finish` |
| PUT | `/sessions/{id}/discount` | `auth.server` | `SessionController@setDiscount` (requires permission `manage_discount`) |
| GET | `/snacks` | `auth.server` | `SnackController@index` |
| POST | `/snacks` | `auth.server` | `SnackController@deal` |
| POST | `/tv/token` | `auth.server` | `TvController@token` |
| GET | `/tv/pin/{pin}` | none | `TvController@resolvePin` |
| GET | `/tv/sessions` | `signed` (route name `tv.sessions`) | `TvController@sessions` |
| GET | `/sessions/{session}` | `private` | `SessionController@show` (route-model bound) |

`OtpController@make`/`@submit` are placeholder stubs (return raw strings) — real OTP flow is `OTPMiddleware`/`OTPGenerateMiddleware`/`OtpClient` from the shared package, not this controller.

### Models

- **Session** (table `game_sessions`) — traits `Authorable`, `HasFactory`. Fillable: `instance_id`, `serviced_by`, `time`, `tariff`, `price`, `status`, `started_at` (`discount` is set directly, not mass-assigned). Relations: `servicedBy(): BelongsTo Employee`, `invoice(): BelongsTo Invoice`. Accessor `end_price` = `round(price * (1 - (discount ?? 0) / 100), 2)`.
- **Invoice** (table `invoices`) — trait `HasFactory`. Fillable: `customer_id`, `status`, `payment_method` (cast `array`), `customer`. Relations: `sessions(): HasMany`, `snackSales(): HasMany`. Accessor `total` = `snackSales.sum('price') + sessions.sum('end_price')`.
- **Employee** (table `employees`) — trait `HasFactory`, no fillable declared. Relation: `sessions(): HasMany` (FK `serviced_by`). All computed attributes are derived from sessions with status `ACTIVE`/`FINISHED`: `serviced_total`, `serviced_minutes_total`, `serviced_in_a_day`, `serviced_minutes_in_a_day`, `serviced_in_a_week`, `serviced_minutes_in_a_week`, `serviced_in_a_month`, `serviced_minutes_in_a_month`, `full_name` (`"{first_name} {last_name}"`).
- **Snack** (table `snacks`) — trait `HasFactory`. Fillable: `stock` (`name`/`price` columns exist but aren't mass-assignable).
- **SnackSale** (table `snack_sales`) — traits `Authorable`, `HasFactory`. Fillable: `snack`, `quantity`, `price`. Relation: `invoice(): BelongsTo`. Accessor `total` = `price * quantity`.

Local app enum: `app/Enums/PeriodFilterEnum` — `TODAY`/`WEEK`/`MONTH`, `startOf(): Carbon`.

No local `database/migrations` directory in this service — table/column shapes are inferred from models + `database/factories/*`.

### Session Store Request (`app/Http/Requests/Session/StoreRequest.php`)

| Field | Rule | Notes |
|---|---|---|
| `instance_id` | required | |
| `serviced_by` | required, `exists:employees,id` | |
| `time` | required, `Rule::enum(SessionTimeEnum::class)` | |
| `schedule` | nullable, boolean | If true: session starts immediately (ACTIVE). Default: queued. |
| `invoice_id` | nullable, integer | Attach to existing open invoice |
| `customer_id` | nullable | CRM customer ID |
| `customer` | nullable, string | Defaults to `'Quest'` via `prepareForValidation()` |

### SessionService

Constructor-injects `InvoiceService`.

- **`today()`** — sessions created today (`servicedBy`, `invoice` eager-loaded), ordered by `created_at` desc. Any session `status === ACTIVE` whose `(started_at ?? created_at) + time` has already passed is flipped **in-memory only** (not saved) to `FINISHED` for display purposes.
- **`active()`** — sessions with status `ACTIVE` or `QUEUE`.
- **`forTV()`** — identical query to `active()`; used by `TvController@sessions`.
- **`create(StoreRequest $request)`**:
  1. Tariff: `EVENING` if `now() > today 12:00:00`, else `MORNING`.
  2. `$startedAt = $request->isScheduled() ? now() : null`.
  3. Calls `DeviceClient::price(PricePayload::forInstance($instanceId, $tariff, $time))`. On `ServiceUnavailableException`, logs and throws a 503 `HttpResponseException`. On a failed (non-2xx) response, re-throws its status/body.
  4. Resolves/creates invoice via `InvoiceService::findOrCreateQueued(invoiceId, customerId, customer)`.
  5. Creates the session on the invoice: `time = time->getMins()`, `price` from the pricing response, `status = isScheduled() ? ACTIVE : QUEUE`, `started_at`.
  6. Fires `event(new SessionCreated($session, isScheduled() ? SessionScheduleActionEnum::START : SessionScheduleActionEnum::QUEUE))`.
- **`cancel(int $id)`** — requires status `QUEUE` or `ACTIVE`. Sets `CANCELED`, fires `SessionCanceled`.
- **`start(int $id)`** — requires `QUEUE`. Sets `ACTIVE` + `started_at = now()`, fires `SessionStarted`.
- **`finish(int $id)`** — requires `ACTIVE`. Sets `FINISHED`, fires `SessionFinished`.
- **`setDiscount(int $id, float $discount)`** — requires `ACTIVE` or `FINISHED`. Sets `discount`, saves. **Fires no event.**

### InvoiceService

- **`all(?InvoiceStatusEnum $status = null, ?PeriodFilterEnum $period = null)`** — optional status/period filters; eager-loads `sessions` excluding `CANCELED`. (Note: the underlying method is named `all`, not `index`.)
- **`findOrCreateQueued(?int $invoiceId, ?int $customerId, string $fallbackCustomer)`** — reuses the given invoice if it exists and is `QUEUE`; otherwise resolves the customer name (starts with `$fallbackCustomer`, overwritten by `CrmClient::customer($customerId)->full_name` if `$customerId` given and CRM is reachable — logs and falls back silently on `ServiceUnavailableException`) and creates a new `QUEUE` invoice.
- **`pay(int $id, array $paymentMethod)`** — `QUEUE` → `PAYED`, stores `payment_method`.
- **`cancel(int $id)`** — `QUEUE` → `CANCELED`.

### Other Services/Controllers
- **EmployeeService::all()** → `Employee::all()`.
- **SnackService** (constructor-injects `InvoiceService`): `all()` → `Snack::all()`; `deal(snackId, quantity, invoiceId?, customerId?, fallbackCustomer)` — resolves/creates a queued invoice, decrements `Snack::stock`, creates a `SnackSale` on the invoice.
- **TvController** — `token()`: builds a 24h signed URL for `tv.sessions`, generates a random 4-digit PIN, caches `pin → url` for 24h, returns `{pin, expires_at}`. `resolvePin($pin)`: looks up the cached URL, 404 JSON if missing/expired. `sessions()`: `SessionResource::collection(SessionService::forTV())`. No dedicated `TvService` — logic lives in the controller via `Cache`/`URL` facades.

### Events Pattern

**This is the section most changed from any earlier version of this doc.** Session events no longer do work in their own constructors — they are plain data carriers, wired up via a standard Laravel subscriber.

- `SessionCreated(public readonly Session $session, public SessionScheduleActionEnum $action)`
- `SessionStarted(public readonly Session $session)`
- `SessionCanceled(public readonly Session $session)`
- `SessionFinished(public readonly Session $session)`

`app/Providers/EventServiceProvider.php`:
```php
protected $subscribe = [SessionScheduleSubscriber::class];
```

`app/Listeners/SessionScheduleSubscriber.php` wires:
| Event | Listener | Action |
|---|---|---|
| `SessionCreated` | `SessionCreatedListener::class` (now **active**, previously dead code) | dispatches `HandleSessionSchedule(instanceId, $event->action, session.time, session.id, session.created_at)->onQueue('device')` + broadcasts `SessionCreatedPublic` + `SessionCreatedPrivate(sessionId, instanceId)` |
| `SessionStarted` | `handleStarted()` | dispatches `HandleSessionSchedule(instanceId, SessionScheduleActionEnum::START, session.time)->onQueue('device')` |
| `SessionFinished` | `handleFinished()` | dispatches `HandleSessionSchedule(instanceId, SessionScheduleActionEnum::FINISH)->onQueue('device')` |
| `SessionCanceled` | `handleCanceled()` | dispatches `HandleSessionSchedule(instanceId, SessionScheduleActionEnum::CANCEL)->onQueue('device')` |

Broadcast events (`app/Events/Broadcast/`): `SessionCreatedPublic` (public `Channel('sessions')`, broadcasts as `SessionCreated`, empty payload), `SessionCreatedPrivate` (`PrivateChannel('sessions')`, broadcasts as `SessionCreated`, payload `{session_id, instance_id}`).

### AppServiceProvider

Registers morph map (nothing else):
- `'staff-session'` → `Session::class`
- `'staff-snack-sale'` → `SnackSale::class`

---

## device-service

### Routes (`routes/api.php`)

Accessible at `/hardware/` via gateway. **There is no root `/` route and no `MeController` in this service.**

| Method | Path | Middleware | Controller |
|---|---|---|---|
| GET | `/games` | — | `GameController@index` |
| POST | `/games/search` | — | `GameController@search` |
| GET | `/games/{id}` | — | `GameController@show` |
| GET | `/posts` | — | `PostController@index` |
| POST | `/schedule` | `private`, `idempotent` | `ScheduleController@store` |
| GET | `/schedule/{id}` (numeric) | `private` | `ScheduleController@activeForInstance` |
| DELETE | `/schedule/{id}` | `private` | `ScheduleController@cancel` |
| GET | `/schedule/{macAddress}` | `OverlaySecretMiddleware`, `throttle:30,1` | `ScheduleController@activeForInstanceByMac` |
| GET | `/tariff-plans` | — | `TariffPlanController@index` |
| POST | `/price` | — | `TariffPlanController@price` — called by `DeviceClient::price()` |
| GET | `/instances` | — | `InstanceController@index` |
| GET | `/instance/{idOrMacAddress}` | — | `InstanceController@show` |
| GET | `/genres` | — | `GenreController@index` |
| GET | `/devices` | — | `DeviceController@index` |

The `private` middleware group around numeric-id schedule routes is **now active** (no longer commented out).

### Models

- **Instance** (table `instances`) — casts `active` bool, `deactivation_start`/`deactivation_end` datetime. `$with = ['schedules']` (always eager-loaded). Relations: `schedules(): HasMany Schedule`, `device(): BelongsTo Device`. Methods:
  - `getActiveSchedule(): ?Schedule` — filters loaded schedules by `isActive()`, sorted by `end` asc, first.
  - `getUpcomingSchedule(): ?Schedule` — schedule with `type !== CANCELED`, `start` in `(now(), now()+15min]` (window = `NotifyUpcomingSchedules::WINDOW_MINUTES`).
  - `findByIdOrMacAddressOrFail($idOrMacAddress)` — MAC lookup if `FILTER_VALIDATE_MAC` passes, else numeric id lookup.
  - `label` accessor — `"{device} - {position}"`, position = count of same-device instances with `id <= $this->id`.
- **Schedule** (table `schedules`) — traits `Authorable`, `HasFactory`. Fillable: `type`, `instance_id`, `start`, `end`, `session_id`. Casts `start`/`end` datetime. Relation: `instance(): BelongsTo`. `isActive(): bool` — not `CANCELED`, and: (`start` & `end` both null → open-ended active) OR (`start` null, `end` in future) OR (`start` passed, `end` null → open-ended) OR (`start` passed, `end` in future). A schedule with a future `start` is **not** active — it's "upcoming".
- **Device** (table `devices`) — `HasMedia`/`InteractsWithMedia`, registers a `logo` media collection. Cast `description` → array.
- **Game** (table `games`) — `HasMedia`, `InteractsWithMedia`, `Pageable`, `HasTranslations` (`$translatable = ['description']`). Cast `multiplayer` bool. `$appends = ['preview']`, `$with = ['genres','devices','media']`. `video` accessor → `null` or `https://www.youtube.com/watch?v={value}`. `preview` accessor → first `preview` media item's `original_url`. Relations: `genres(): BelongsToMany` (pivot `game_genre`), `devices(): BelongsToMany(Device::class, 'game_device', 'game_id', 'device', 'id', 'type')` (custom pivot column names).
- **Genre** (table `genres`) — plain model.
- **Post** (table `posts`) — `Pageable` trait. Cast `post` → array (plain array cast, not `HasTranslations` unlike Game).
- **TariffPlan** (table `tariff_plans`) — fields `tariff` (`SessionTariffEnum`), `time` (`SessionTimeEnum`), `price`, `device` (`DeviceEnum`).

No local `database/migrations` — inferred from models + `database/factories/*`.

### SessionScheduleHandler

Implements `SessionScheduleHandlerInterface`. Bound in `DependencyInjectionServiceProvider`. Signature now takes `SessionScheduleActionEnum $action` (not a raw string). Full logic, inside `DB::transaction`:

1. Lock the `Instance` row (`lockForUpdate()`); return early if not found.
2. Lock all its schedules (`lockForUpdate()->get()`), filter to `isActive()`, sort by `end`, take the first → `$active`.
3. **If `$active` exists and is type `QUEUE`:**
   - `action === START` → reuse/update that same schedule row to `IN_SESSION` (`ScheduleService::save()`), dispatch `ScheduleUpdated($updated, 'updated')`, **return**.
   - `action === CANCEL` → cancel it, dispatch `ScheduleUpdated($cancelled, 'cancelled')`, **return**.
   - (QUEUE-while-QUEUE and FINISH-of-QUEUE are *not* special-cased and fall through to step 4.)
4. **If `$active` exists** (reached only when step 3 didn't return): cancel it, dispatch `ScheduleUpdated($cancelled, 'cancelled')`. No early return — execution continues.
5. Then:
   - `action === QUEUE` → create a new `QUEUE` schedule, dispatch `ScheduleUpdated($schedule, 'created')`.
   - `action === START` → create a new `IN_SESSION` schedule, dispatch `ScheduleUpdated($schedule, 'created')`.
   - `FINISH`/`CANCEL` produce **no new schedule** here — their only possible dispatch is the `'cancelled'` one from steps 3/4. If there was no active schedule at all, `FINISH`/`CANCEL` dispatch **nothing**.

`ScheduleUpdated`'s `$action` is a plain `string` (`'created'`/`'updated'`/`'cancelled'`), independent of `SessionScheduleActionEnum`. `NotifyUpcomingSchedules` separately broadcasts with the literal action `'upcoming'`, bypassing this handler and the `ScheduleUpdated` event entirely (see below).

### ScheduleController

Constructor-injects `ScheduleService`.

- **`store(StoreRequest $request)`** — builds a `SchedulePayload`, calls `ScheduleService::create()` (validates `type` as `ScheduleEnum`, `instance_id` exists & active, `start` required + no overlapping non-canceled schedule for that instance, `end` nullable/after `start`). `ScheduleService::create()` dispatches `ScheduleUpdated($schedule, 'created')` itself.
- **`activeForInstance(int $id)`** — `Instance::findOrFail($id)->getActiveSchedule()`.
- **`activeForInstanceByMac(string $macAddress)`** — `Instance::where('mac_address', $macAddress)->firstOrFail()->getActiveSchedule()`. Behind `OverlaySecretMiddleware` (see Overlay Feature below).
- **`cancel(int $id)`** — `ScheduleService::cancel($id)` marks the schedule `CANCELED`. **Dispatches no event** — unlike `SessionScheduleHandler`, the controller's `cancel` path does not call `ScheduleUpdated::dispatch()`, so `DELETE /schedule/{id}` never triggers any WebSocket broadcast.
- All three GET/POST responses go through a shared `scheduleResponse()` helper: builds `ScheduleResource`; if the schedule has `session_id`, enriches it with `serviced_by_name`/`customer` via `StaffClient::sessionById()` (catches `ServiceUnavailableException`, logs, degrades gracefully).

### Scheduled Jobs (`ScheduleServiceProvider` — both run every minute)

- **`CleanOldSchedules`** (`ShouldQueue`) — `Schedule::where('type', CANCELED)->orWhere('end', '<', now())->delete()`. Hard delete, no events dispatched.
- **`NotifyUpcomingSchedules`** (plain job, not `ShouldQueue`) — `WINDOW_MINUTES = 15`. For every schedule with `start` in `(now(), now()+15min]` and not `CANCELED`: broadcasts `ScheduleUpdatedPrivate($schedule, 'upcoming')` + `ScheduleUpdatedPublic($schedule)`. **Does not broadcast `ScheduleUpdatedOverlay`** — the overlay only receives create/update/cancel notifications via `ScheduleUpdatedListener`, never the 15-minute "upcoming" warning.

### Overlay Feature (new — not in earlier versions of this doc)

The VR device screen overlay is fed by a MAC-address-scoped, secret-protected channel rather than living as a project in this repo:

- **`GET /schedule/{macAddress}`** — guarded by `App\Http\Middleware\OverlaySecretMiddleware`: reads `X-Overlay-Secret` header, `hash_equals()` against `config('service.overlay_secret')` (env `OVERLAY_SECRET`, merged from the shared package's `config/service.php`); throws `AuthenticationException` if empty/mismatched. Also throttled `30,1`.
- **`app/Events/Broadcast/ScheduleUpdatedOverlay`** (`ShouldBroadcast`) — broadcasts on a private channel `schedule.{MAC-slug}.{overlay_secret}` (MAC uppercased, non-alphanumerics stripped), broadcast name `ScheduleUpdated`. Payload: `ScheduleResource`, enriched with `servicedByName`/`customer` from `StaffClient::sessionById()` when applicable (degrades gracefully on `ServiceUnavailableException`), plus `sent_by: 'device-service'`.
- Dispatched only from **`ScheduleUpdatedListener`** (see EventServiceProvider below) — i.e. only for the `created`/`updated`/`cancelled` actions coming out of `SessionScheduleHandler`/`ScheduleService::create()`, never for the `'upcoming'` notification.
- `routes/channels.php` is referenced by `bootstrap/app.php` (`withRouting`/`withBroadcasting`) but **does not exist on disk** in this service — worth confirming with the team whether broadcast channel-auth callbacks live elsewhere.

### Providers

- `DependencyInjectionServiceProvider` — binds `SessionScheduleHandlerInterface` → `SessionScheduleHandler`.
- `EventServiceProvider` — **now active** (previously commented out):
  ```php
  protected $listen = [ScheduleUpdated::class => [ScheduleUpdatedListener::class]];
  ```
  `ScheduleUpdatedListener::handle()` broadcasts **three** events: `ScheduleUpdatedPublic($schedule)`, `ScheduleUpdatedPrivate($schedule, $action)`, `ScheduleUpdatedOverlay($schedule)`. Note `ScheduleUpdated`'s constructor now carries the full `Schedule` model plus `string $action`, not just an instance id.
- `MorphMapServiceProvider` — morph map: `'device-game'` → `Game::class`, `'device-model'` → `Device::class`.
- `ScheduleServiceProvider` — registers the two cron jobs above.

Provider boot order (`bootstrap/providers.php`): `DependencyInjectionServiceProvider`, `EventServiceProvider`, `MorphMapServiceProvider`, `ScheduleServiceProvider`, then shared `SharedServiceProvider`.

---

## Databases

- Each Laravel service has its **own default database** (staff-service → staff DB, device-service → device DB, etc.), each with a `-default` (app user) and `-admin` (elevated, mainly for adminpanel) env file.
- `db_shared` — shared database used by ALL services for:
  - `jobs` table (queue)
  - `authors` table (`Authorable` trait)
  - `job_batches` table
  - `hostnames`, `idempotency_keys`, `media` (shared package models)

Connection `db_shared` is configured dynamically by `SharedServiceProvider` via `Config::set()` using `DB_SHARED_*` env vars.

### `docker/env/` (19 files)

| Group | Files |
|---|---|
| Per-service app-user DB creds | `db-auth-default.env`, `db-configs-default.env`, `db-crm-default.env`, `db-device-default.env`, `db-staff-default.env` |
| Per-service admin DB creds | `db-admin-default.env`, `db-auth-admin.env`, `db-configs-admin.env`, `db-crm-admin.env`, `db-device-admin.env`, `db-staff-admin.env` |
| Shared | `db-shared-admin.env` |
| Infrastructure | `apache.env`, `laravel.env`, `redis.env`, `mail.env`, `otel.env` (OpenTelemetry), `rabbitmq.env`, `reverb.env`, `s3.env` |

---

## Docker

**Base image:** `docker/phober-php/Dockerfile` — PHP 8.2 + Apache. Entrypoint: `apache2 -D FOREGROUND`. No queue workers run automatically — must be started manually per service (or via the dedicated worker containers in `docker-compose.realtime.yml`).

**Compose files** (6 total; no plain `docker-compose.yml` base file):

| File | Compose project | Services |
|---|---|---|
| `docker-compose.backend.yml` | `phober-backend` | `nginx-proxy-manager`, `api-gateway`, `adminpanel`, `auth-server`, `config-server`, `notification-server`, `device-service`, `crm-service`, `staff-service` |
| `docker-compose.db.yml` | `phober-db` | `db_mysql` (MySQL 8), `redis` (7), `minio` (backed by `./buckets`); `rabbitmq` present but commented out |
| `docker-compose.realtime.yml` | `phober-realtime` | `notification-queue`, `staff-queue`, `device-queue`, `device-schedule` (scheduler; `staff-schedule` commented out), `ws` (Reverb, port 8080) |
| `docker-compose.frontend.yml` | `phober-frontend` | `staff-app` (Node 20, `npm run dev`), `website` (`nginx:alpine`) |
| `docker-compose.elk.yml` | `phober-elk` | `elasticsearch`, `logstash`, `kibana` |
| `docker-compose.observability.yml` | `phober-observability` | `dozzle` (log viewer), `buggregator` (Sentry-compatible local error tracker — every backend service's `SENTRY_DSN` points here), `zipkin` (tracing UI), `ws-inspector` (Reverb inspector) |

**Runtime env (all services):** `APP_ENV=local`, `APP_DEBUG=true`, `APP_TIMEZONE=Asia/Baku`, `TELESCOPE_ENABLED=true`, `QUEUE_CONNECTION=database`, `QUEUE_FAILED_DRIVER=database-uuids`.

**Setup:** `setup.sh`/`setup-mac.sh` (repo root) present a checkbox menu to (1) run `docker/mysql/init-db.sql` to create per-service databases and (2) `composer install && composer update` inside each of the 7 Laravel service containers. Neither script touches `staff-app`/`website`.

---

## Session Lifecycle — Full Flow

```
POST /staff/sessions (store)
  → SessionService::create() determines tariff (MORNING before noon, EVENING after)
  → DeviceClient::price() to get price
  → InvoiceService::findOrCreateQueued() to get/create invoice
  → session created on invoice
  → event(SessionCreated($session, $action))
      schedule=false → action=QUEUE,  status=QUEUE
      schedule=true  → action=START,  status=ACTIVE, started_at=now()
  → SessionScheduleSubscriber → SessionCreatedListener:
      HandleSessionSchedule dispatched to 'device' queue
      broadcast(SessionCreatedPublic) + broadcast(SessionCreatedPrivate)
  → device-queue worker → SessionScheduleHandler::handle()
      creates/updates a Schedule row on the Instance
      dispatch(ScheduleUpdated($schedule, 'created'|'updated'|'cancelled'))
  → ScheduleUpdatedListener broadcasts ScheduleUpdatedPublic + ScheduleUpdatedPrivate + ScheduleUpdatedOverlay

PUT /staff/sessions/{id}/start  (only if status=QUEUE)
  → status=ACTIVE, started_at=now()
  → event(SessionStarted) → SessionScheduleSubscriber::handleStarted()
      HandleSessionSchedule(instanceId, START, time) → 'device' queue

DELETE /staff/sessions/{id}  (if status=QUEUE or ACTIVE)
  → status=CANCELED
  → event(SessionCanceled) → SessionScheduleSubscriber::handleCanceled()
      HandleSessionSchedule(instanceId, CANCEL) → 'device' queue

PUT /staff/sessions/{id}/finish  (only if status=ACTIVE)
  → status=FINISHED
  → event(SessionFinished) → SessionScheduleSubscriber::handleFinished()
      HandleSessionSchedule(instanceId, FINISH) → 'device' queue

PUT /staff/sessions/{id}/discount  (if ACTIVE or FINISHED, requires permission manage_discount)
  → sets discount, end_price recalculated on read (no event fired)
```

---

## Inter-Service Communication

| From | To | Mechanism | Purpose |
|---|---|---|---|
| staff-service | device-service | HTTP (`DeviceClient::price`) | Get session price |
| staff-service | device-service | Queue job (`HandleSessionSchedule`) | Sync session state to device schedule |
| device-service | staff-service | HTTP (`StaffClient::sessionById`) | Enrich schedule responses / overlay payload with session details |
| staff-service | crm-service | HTTP (`CrmClient::customer`) | Resolve customer name from ID |
| all services | auth-server | HTTP (`AuthClient`) via `AuthServerMiddleware` | Token validation |
| all services | config-server | HTTP (`ConfigClient`) | Runtime config sync (`.env.shared`) |
| device-service | WebSocket clients (Reverb) | Broadcast | `ScheduleUpdatedPublic`/`Private` — live schedule updates, including the 15-min "upcoming" warning |
| device-service | External VR overlay client | Broadcast on `schedule.{MAC}.{secret}` channel | `ScheduleUpdatedOverlay` — schedule state for the physical device screen (create/update/cancel only, not "upcoming") |
| External VR overlay client | device-service | HTTP `GET /schedule/{macAddress}` with `X-Overlay-Secret` header | Initial/poll fetch of the active schedule for a device |
| staff-service | WebSocket clients (Reverb) | Broadcast | `SessionCreatedPublic`/`Private` |
| staff-app (React) | API gateway + Reverb | HTTP (`/auth/`, `/crm/`, `/hardware/`, `/staff/`) + WebSocket (`laravel-echo`) | Staff dashboard UI |
