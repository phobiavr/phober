<?php

namespace Shared\Clients;

use DateTime;
use GuzzleHttp\Promise\PromiseInterface;
use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Http;
use Shared\Enums\ScheduleEnum;

class DeviceClient {
    protected static ?string $url = 'http://device-service';

    public static function schedule(ScheduleEnum $type, int $instanceId, DateTime $start, DateTime $end = null): PromiseInterface|Response|bool {
        return Http::accept('application/json')->withHeaders([
            'Authorization' => 'Bearer ' . request()->bearerToken()
        ])->post(self::$url . '/schedule', [
            "type"        => $type->value,
            "instance_id" => $instanceId,
            "start"       => $start->format('Y-m-d H:i:s'),
            "end"         => $end?->format('Y-m-d H:i:s')
        ]);
    }
}
