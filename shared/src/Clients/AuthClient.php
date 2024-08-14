<?php

namespace Shared\Clients;

use Illuminate\Http\Response;
use Illuminate\Support\Facades\Http;

class AuthClient extends Client {

    public static function getUrl(): string {
        return static::$url ??= env('AUTH_SERVER', 'http://auth-server');
    }

    public static function login() {
        $response = Http::accept('application/json')->withHeaders([
            'Authorization' => 'Bearer ' . request()->bearerToken()
        ])->get(self::getUrl() . '/valid');

        return $response->status() === Response::HTTP_OK ? $response['user'] : null;
    }
}
