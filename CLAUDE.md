# Phober — Complete Project Context

## Overview

**Phober** is a VR gaming hall management system. Staff manage sessions on VR devices, handle billing (invoices), and track employees. Devices run a desktop overlay (WPF/C#) that shows the current session schedule on-screen.

**Stack:** Laravel 11, PHP 8.2, Apache, MySQL, Docker, Reverb (WebSockets), MinIO (S3).

---

## Microservices

| Container | Path | DB Queue | Purpose |
|---|---|---|---|
| `staff-service` | `services/staff-service` | `staff` | Sessions, employees, invoices, snacks |
| `device-service` | `services/device-service` | `device` | VR device instances, schedules, games, tariffs |
| `adminpanel` | `services/adminpanel` | `adminpanel` | Admin panel |
| `auth-server` | `services/auth-server` | `auth` | Authentication |
| `config-server` | `services/config-server` | `config` | Runtime configuration |
| `notification-server` | `services/notification-server` | `notification` | Notifications |
| `crm-service` | `services/crm-service` | `crm` | CRM (customers, loyalty) |

**Desktop overlay:** `services/desktop-overlay/` — WPF/C# app (Phober.Overlay.csproj). Displays live session schedule on the VR device screen. Does NOT make HTTP calls to session endpoints. Receives data via WebSocket (Reverb).

---

## API Gateway

Nginx: `docker/api-gateway/nginx.conf`. Single entrypoint: `api.phober.test`.

| URL prefix | Upstream |
|---|---|
| `/staff/` | `staff-service:80` |
| `/hardware/` | `device-service:80` |
| `/auth/` | `auth-server:80` |
| `/crm/` | `crm-service:80` |
| `/configs/` | `config-server:80` |
| `/ws/` | Reverb WebSocket |
| `/s3/` | MinIO |

---

## Shared Package: `laravel-common`

Path: `shared/laravel-common/`. Mounted into every service as a Composer package:
```
./shared/laravel-common:/var/www/html/vendor/phobiavr/phober-laravel-common
```
Namespace: `Phobiavr\PhoberLaravelCommon`.

### Jobs
- `Jobs/HandleSessionSchedule` — queued job that syncs session state to device-service. Implements `ShouldQueue`. Constructor params: `int $instanceId`, `string $action`, `?int $time`, `?int $sessionId`, `?string $startedAt`. The `handle()` method resolves `SessionScheduleHandlerInterface` from the container and delegates to it.

### Contracts
- `Contracts/SessionScheduleHandlerInterface` — implemented by `SessionScheduleHandler` in device-service (bound via `DependencyInjectionServiceProvider`).

### HTTP Clients
All clients use `Http::` facade, talk container-to-container by service name.

| Client | Base URL | Methods |
|---|---|---|
| `DeviceClient` | `http://device-service` | `price($instanceId, $tariff, $time)`, `schedule(...)`, `deleteSchedule($id)` |
| `StaffClient` | `http://staff-service` | `sessionById($sessionId)` |
| `CrmClient` | `http://crm-service` | `customer($customerId)` |
| `AuthClient` | `http://auth-server` | auth operations |
| `ConfigClient` | `http://config-server` | config sync |
| `NotificationClient` | notification calls |
| `OtpClient` | OTP calls |

### Traits
- `Traits/Authorable` — adds `bootAuthorable()` to Eloquent models. On `created`: inserts into `authors` table (db_shared) with `created_by` = Auth user. On `updated`: updates `last_updated_by`. Relationship: `author()` → `MorphOne(Author::class)`.

### Models
- `Author` — polymorphic model. Connection: `db_shared`. Fields: `created_by`, `last_updated_by`, `updated_at`. Appends: `authorable_created_at`, `authorable_updated_at`.

### Enums
| Enum | Values |
|---|---|
| `SessionStatusEnum` | `QUEUE`, `ACTIVE`, `CANCELED`, `FINISHED` |
| `SessionTimeEnum` | `MIN_15` (15min), `MIN_30` (30min), `MIN_60` (60min) — `getMins()` returns int |
| `SessionTariffEnum` | `MORNING`, `EVENING`, `EXTRA` — determined by time of day (before/after noon) |
| `ScheduleEnum` | `MAINTENANCE`, `RESERVATION`, `INSPECTION`, `REPAIR`, `IN_USE`, `IN_SESSION`, `QUEUE`, `ON_EVENT`, `CANCELED` |
| `InvoiceStatusEnum` | `QUEUE`, `PAYED`, `CANCELED` |
| `InvoicePaymentMethodEnum` | payment methods |
| `ReservationStatusEnum`, `ReservationRequestEnum` | reservations |
| `LoyaltyCardStatusEnum`, `CustomerStatusEnum`, `GenderEnum`, `ContactTypeEnum` | CRM |
| `DeviceEnum` | device types |

### SharedServiceProvider
- Merges `config/features.php`
- Loads routes: `health`, `instance-info`, `config-client/update` (private middleware)
- Pushes middleware: `ForceJsonMiddleware`, `TranslationMiddleware`
- Aliases: `auth.server` → `AuthServerMiddleware`, `otp` → `OTPMiddleware`, `otp.generate` → `OTPGenerateMiddleware`, `private` → `PrivateMiddleware`
- Registers `json` Auth guard (`JsonGuard`)
- Sets `database.connections.db_shared` from env (`DB_SHARED_*`)

---

## Queue System

**Driver:** `database` for all services.  
**Connection:** `db_shared` — shared MySQL database. Table: `jobs`.  
**Each service has its own named queue** (`DB_QUEUE` env var). Jobs are written to `db_shared.jobs` with the appropriate `queue` column value.

The queue worker for each service must be started manually — Apache is the container entrypoint, no worker runs automatically inside containers.

`HandleSessionSchedule` is dispatched from `staff-service` to `->onQueue('device')`. It lands in `db_shared.jobs` with `queue='device'`. The device-service worker (`php artisan queue:work --queue=device`) picks it up and executes `SessionScheduleHandler::handle()`.

---

## staff-service

### Routes (`routes/api.php`)

All staff routes are prefixed `/staff/` at the gateway level (stripped before hitting the service).

| Method | Path | Auth | Controller |
|---|---|---|---|
| GET | `/otp/make` | otp.generate | OtpController@make |
| GET | `/otp/submit` | otp | OtpController@submit |
| GET | `` (root) | auth.server | MeController@show |
| GET | `/employees` | auth.server | EmployeeController@index |
| GET | `/invoices` | auth.server | InvoiceController@index |
| PUT | `/invoices/{id}` | auth.server | InvoiceController@pay |
| DELETE | `/invoices/{id}` | auth.server | InvoiceController@cancel |
| GET | `/sessions/today` | auth.server | SessionController@today |
| GET | `/sessions` | auth.server | SessionController@active |
| POST | `/sessions` | auth.server | SessionController@store |
| DELETE | `/sessions/{id}` | auth.server | SessionController@cancel |
| PUT | `/sessions/{id}/start` | auth.server | SessionController@start |
| PUT | `/sessions/{id}/finish` | auth.server | SessionController@finish |
| GET | `/sessions/{id}/discount/{discount}` | auth.server | SessionController@setDiscount |
| GET | `/snacks` | auth.server | SnackController@index |
| POST | `/snacks` | auth.server | SnackController@deal |
| POST | `/tv/token` | auth.server | TvController@token |
| GET | `/tv/pin/{pin}` | none | TvController@resolvePin |
| GET | `/tv/sessions` | signed URL | TvController@sessions |
| GET | `/sessions/{session}` | private | SessionController@show |

### Models

**Session** — table: `game_sessions`. Uses `Authorable`. Fields: `instance_id`, `serviced_by`, `time` (minutes), `tariff`, `price`, `discount`, `status`, `started_at`. Computed: `end_price` = `price * (1 - discount * 0.1)`. Relations: `servicedBy()` → Employee, `invoice()` → Invoice.

**Invoice** — Fields: `customer_id`, `status`, `payment_method` (JSON array), `customer` (name string). Relations: `sessions()` → hasMany Session, `snackSales()` → hasMany SnackSale. Computed: `total` = sum of snack sales + sum of session end_prices.

**Employee** — Relations: `sessions()` → hasMany Session (via `serviced_by`). Computed attributes (all filtered to ACTIVE/FINISHED sessions): `serviced_total`, `serviced_minutes_total`, `serviced_in_a_day`, `serviced_minutes_in_a_day`, `serviced_in_a_week`, `serviced_minutes_in_a_week`, `serviced_in_a_month`, `serviced_minutes_in_a_month`, `full_name`.

**Snack**, **SnackSale** — snack inventory and sales.

### Session Store Request (`StoreRequest`)

| Field | Type | Notes |
|---|---|---|
| `instance_id` | required | VR device instance ID |
| `serviced_by` | required | Employee ID (must exist) |
| `time` | required | `SessionTimeEnum` value (`MIN_15`/`MIN_30`/`MIN_60`) |
| `schedule` | nullable bool | If true: session starts immediately (ACTIVE). Default: queued. |
| `invoice_id` | nullable int | Attach to existing open invoice |
| `customer_id` | nullable | CRM customer ID |
| `customer` | nullable string | Customer name. Defaults to `'Quest'` |

### SessionService

**`today()`** — returns all sessions created today, with `servicedBy` + `invoice`. If a session is ACTIVE but its time has elapsed (`started_at + time < now()`), status is overridden to FINISHED in-memory (not saved).

**`active()`** — returns sessions with status QUEUE or ACTIVE.

**`create(StoreRequest $request)`**:
1. Determines tariff: MORNING if before noon (12:00), EVENING otherwise.
2. Calls `DeviceClient::price($instanceId, $tariff, $time)` — throws 4xx/5xx if fails.
3. Calls `InvoiceService::findOrCreateQueued(invoiceId, customerId, customer)` — reuses open invoice or creates new (fetching customer name from CRM if `customerId` provided).
4. Creates session on the invoice.
5. If `isScheduled() = false`: status=QUEUE, started_at=null, action=`'queue'`.
   If `isScheduled() = true`: status=ACTIVE, started_at=now(), action=`'start'`.
6. Dispatches `HandleSessionSchedule($instanceId, $action, $time, $sessionId, $session->created_at->toIso8601String())->onQueue('device')`.
7. Fires `SessionCreated` event → `SessionCreatedListener` → broadcasts `SessionCreatedPublic` + `SessionCreatedPrivate($sessionId, $instanceId)`.

**`start(int $id)`** — requires QUEUE status. Sets ACTIVE + `started_at = now()`. Fires `SessionStarted($session)` → dispatches `HandleSessionSchedule($instanceId, 'start', $time, $sessionId, $startedAt)->onQueue('device')`.

**`cancel(int $id)`** — requires QUEUE or ACTIVE. Sets CANCELED. Fires `SessionCanceled($session)` → dispatches `HandleSessionSchedule($instanceId, 'cancel')->onQueue('device')`.

**`finish(int $id)`** — requires ACTIVE. Sets FINISHED. Fires `SessionFinished($session)` → dispatches `HandleSessionSchedule($instanceId, 'finish')->onQueue('device')`.

**`setDiscount(int $id, float $discount)`** — requires ACTIVE or FINISHED. Sets discount (1–5, meaning 10%–50%). `end_price = price * (1 - discount * 0.1)`.

### InvoiceService

**`findOrCreateQueued(?int $invoiceId, ?int $customerId, string $fallbackCustomer)`**: If `invoiceId` given and invoice is QUEUE status → reuse it. Otherwise, create new QUEUE invoice. If `customerId` given, fetches `full_name` from CRM via `CrmClient::customer()`.

**`pay(int $id, array $paymentMethod)`** — QUEUE → PAYED.

**`cancel(int $id)`** — QUEUE → CANCELED.

### Events Pattern

`SessionStarted`, `SessionCanceled`, `SessionFinished` dispatch `HandleSessionSchedule` **inside their own constructor** — no external subscriber. This prevents double-dispatch that occurred with the old `SessionScheduleSubscriber` pattern.

`SessionCreated` is a broadcast-only event (no queue job dispatch). It triggers `SessionCreatedListener` → broadcasts two WebSocket events.

### EventServiceProvider

Only one listener registered: `SessionCreated` → `SessionCreatedListener`. No `$subscribe` array.

### AppServiceProvider

Registers morph map:
- `'staff-session'` → `Session::class`
- `'staff-snack-sale'` → `SnackSale::class`

---

## device-service

### Routes (`routes/api.php`)

Accessible at `/hardware/` via gateway.

| Method | Path | Notes |
|---|---|---|
| GET | `` (root) | auth.server — MeController@show |
| GET | `/games` | GameController@index |
| POST | `/games/search` | GameController@search |
| GET | `/games/{id}` | GameController@show |
| GET | `/posts` | PostController@index |
| POST | `/schedule` | ScheduleController@store |
| GET | `/schedule/{idOrMacAddress}` | ScheduleController@activeForInstance |
| DELETE | `/schedule/{id}` | ScheduleController@cancel |
| GET | `/tariff-plans` | TariffPlanController@index |
| POST | `/price` | TariffPlanController@price — called by DeviceClient::price() |
| GET | `/instances` | InstanceController@index |
| GET | `/instance/{idOrMacAddress}` | InstanceController@show |
| GET | `/genres` | GenreController@index |
| GET | `/devices` | DeviceController@index |

The `private` middleware group around schedule routes is commented out.

### Models

**Instance** — VR device slot. Fields include `mac_address`, `device` (type), `active`, `deactivation_start`, `deactivation_end`. Relations: `schedules()` → hasMany Schedule, `device()` → BelongsTo Device. Always eager-loads `schedules`. Methods: `getActiveSchedule()` — returns first active (not CANCELED, within time window) schedule sorted by `end`. `getUpcomingSchedule()` — schedule starting within the next 15 minutes. `findByIdOrMacAddressOrFail($idOrMacAddress)` — looks up by MAC address (if valid MAC format) or by ID.

**Schedule** — Fields: `type` (ScheduleEnum), `start` (datetime), `end` (datetime), `instance_id`, `session_id`. Uses `Authorable`. `isActive()`: type is not CANCELED AND now is within `[start, end]` window (handles nulls for open-ended ranges).

**Device**, **Game**, **Genre**, **Post**, **TariffPlan** — supporting models.

### SessionScheduleHandler

Implements `SessionScheduleHandlerInterface`. Bound in `DependencyInjectionServiceProvider`.

```
handle($instanceId, $action, $time, $sessionId, $startedAt):
  - Finds Instance, returns early if not found
  - Gets $active = instance->getActiveSchedule()

  If $active is QUEUE type:
    action='start' → update QUEUE schedule to IN_SESSION (reuses same record), dispatch ScheduleUpdated('updated'), return
    action='cancelled' → cancel that schedule, dispatch ScheduleUpdated('cancelled'), return

  If $active exists (and wasn't handled above):
    → cancel it, dispatch ScheduleUpdated('cancelled')

  if action='queue' → create new QUEUE schedule, dispatch ScheduleUpdated('created')
  if action='start' → create new IN_SESSION schedule, dispatch ScheduleUpdated('created')
  (action='cancel'/'finish' fall through the if($active) cancel and do nothing more)
```

Note: the dispatched `action` for cancel is `'cancel'` (from `SessionCanceled`), but the handler explicitly checks for `'cancelled'` — so cancel/finish both fall through to the generic `if ($active)` cancel path. This is intentional: any active schedule gets cancelled regardless.

`ScheduleUpdated` event is dispatched after each action, but `ScheduleUpdatedListener` is **commented out** in `EventServiceProvider`. When uncommented it would broadcast `ScheduleUpdatedPublic($instanceId)` + `ScheduleUpdatedPrivate($scheduleId, $instanceId, $action)` via WebSocket.

### Scheduled Jobs (ScheduleServiceProvider — runs every minute)

- `CleanOldSchedules` — deletes CANCELED schedules and schedules whose `end` is in the past.
- `NotifyUpcomingSchedules` — finds schedules starting within the next 15 minutes, broadcasts `ScheduleUpdatedPrivate($id, $instanceId, 'upcoming')` + `ScheduleUpdatedPublic($instanceId)` for each.

### ScheduleController

`activeForInstance($idOrMacAddress)` — returns active schedule. If schedule has `session_id`, fetches session data from staff-service via `StaffClient::sessionById()` to populate `serviced_by_name` and `customer` fields on the resource.

### Providers

- `DependencyInjectionServiceProvider` — binds `SessionScheduleHandlerInterface` → `SessionScheduleHandler`
- `ScheduleServiceProvider` — registers artisan scheduler jobs (CleanOldSchedules, NotifyUpcomingSchedules)
- `MorphMapServiceProvider` — morph map for device-service models
- `EventServiceProvider` — `ScheduleUpdatedListener` is commented out

---

## Databases

- Each service has its **own default database** (staff-service → staff DB, device-service → device DB, etc.)
- `db_shared` — shared database used by ALL services for:
  - `jobs` table (queue)
  - `authors` table (Authorable trait)
  - `job_batches` table

Connection `db_shared` is configured dynamically by `SharedServiceProvider` via `Config::set()` using `DB_SHARED_*` env vars.

Env files:
- `docker/env/db-staff-default.env` — staff-service own DB
- `docker/env/db-device-default.env` — device-service own DB
- `docker/env/db-shared-admin.env` — shared DB (used by all services for queues/authors)

---

## Docker

**Base image:** `docker/phober-php/Dockerfile` — PHP 8.2 + Apache. Entrypoint: `apache2 -D FOREGROUND`. No queue workers run automatically — must be started manually per service.

**Networks:** `phober_private` (internal), `phober_public` (exposed).

**Compose files:**
- `docker-compose.backend.yml` — all application services
- `docker-compose.db.yml` — databases
- `docker-compose.realtime.yml` — WebSocket / Reverb
- `docker-compose.frontend.yml` — frontend
- `docker-compose.elk.yml` — ELK logging stack

**Env files directory:** `docker/env/`

**Runtime env (all services):**
- `APP_ENV=local`, `APP_DEBUG=true`
- `APP_TIMEZONE=Asia/Baku`
- `TELESCOPE_ENABLED=true`
- `QUEUE_CONNECTION=database`
- `QUEUE_FAILED_DRIVER=database-uuids`

---

## Session Lifecycle — Full Flow

```
POST /staff/sessions (store)
  → create() determines tariff (MORNING before noon, EVENING after)
  → DeviceClient::price() to get price
  → InvoiceService::findOrCreateQueued() to get/create invoice
  → session created on invoice
  → HandleSessionSchedule dispatched to 'device' queue
      if schedule=false: action='queue', status=QUEUE
      if schedule=true:  action='start', status=ACTIVE
  → SessionCreated event → broadcast via WebSocket

PUT /staff/sessions/{id}/start  (only if status=QUEUE)
  → status=ACTIVE, started_at=now()
  → SessionStarted event constructor → HandleSessionSchedule('start', time, sessionId, startedAt) → 'device' queue
  
DELETE /staff/sessions/{id}  (if status=QUEUE or ACTIVE)
  → status=CANCELED
  → SessionCanceled event constructor → HandleSessionSchedule('cancel') → 'device' queue

PUT /staff/sessions/{id}/finish  (only if status=ACTIVE)
  → status=FINISHED
  → SessionFinished event constructor → HandleSessionSchedule('finish') → 'device' queue

GET /staff/sessions/{id}/discount/{discount}  (if ACTIVE or FINISHED)
  → sets discount, recalculates end_price
```

---

## Inter-Service Communication

| From | To | Mechanism | Purpose |
|---|---|---|---|
| staff-service | device-service | HTTP (DeviceClient) | Get session price |
| staff-service | device-service | Queue job (HandleSessionSchedule) | Sync session state to device schedule |
| device-service | staff-service | HTTP (StaffClient) | Get session details for schedule display |
| staff-service | crm-service | HTTP (CrmClient) | Resolve customer name from ID |
| all services | auth-server | HTTP (AuthClient / middleware) | Token validation |
| all services | config-server | HTTP (ConfigClient) | Runtime config |
| device-service | WebSocket clients | Reverb broadcast | Live schedule updates |
| staff-service | WebSocket clients | Reverb broadcast | Session created events |
