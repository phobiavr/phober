<?php

namespace Shared\Clients;

use GuzzleHttp\Promise\PromiseInterface;
use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Http;

class StaffClient {
    protected static ?string $url = 'http://staff-service';

    public static function sessionByScheduleId(int $scheduleId): PromiseInterface|Response {
        return Http::accept('application/json')
            ->withHeaders(['X-APP-KEY' => env('APP_KEY')])
            ->get(self::$url . '/sessions/byScheduleId/' . $scheduleId);
    }
}
