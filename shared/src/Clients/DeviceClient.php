<?php

namespace Shared\Clients;

use DateTime;
use GuzzleHttp\Promise\PromiseInterface;
use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Http;
use Shared\Enums\ScheduleEnum;
use Shared\Enums\SessionTariffEnum;
use Shared\Enums\SessionTimeEnum;

class DeviceClient {
    protected static ?string $url = 'http://device-service';

    public static function schedule(ScheduleEnum $type, int $instanceId, DateTime $start, DateTime $end = null): PromiseInterface|Response {
        return Http::accept('application/json')->withHeaders([
            'Authorization' => 'Bearer ' . request()->bearerToken()
        ])->post(self::$url . '/schedule', [
            "type"        => $type->value,
            "instance_id" => $instanceId,
            "start"       => $start->format('Y-m-d H:i:s'),
            "end"         => $end?->format('Y-m-d H:i:s')
        ]);
    }

    public static function price(int $instanceId, SessionTariffEnum $tariff, SessionTimeEnum $time): PromiseInterface|Response {
        return Http::accept('application/json')->post(self::$url . '/price', [
            "instance_id" => $instanceId,
            "tariff"      => $tariff->value,
            "time"        => $time->value,
        ]);
    }
}
