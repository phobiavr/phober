<?php

namespace Shared\Clients;

use GuzzleHttp\Promise\PromiseInterface;
use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Http;

class CrmClient {
    protected static ?string $url = 'http://crm-service';

    public static function customer(int $customerId): PromiseInterface|Response {
        return Http::accept('application/json')->withHeaders(['X-APP-KEY' => env('APP_KEY')])->get(self::$url . '/customers/' . $customerId);
    }
}
