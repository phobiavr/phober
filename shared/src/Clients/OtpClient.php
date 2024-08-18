<?php

namespace Shared\Clients;

use Illuminate\Http\Response;
use Illuminate\Support\Facades\Http;

class OtpClient {
    protected static ?string $url = 'http://auth-server/otp';
    public int $digits = 4;
    public int $validity = 10;
    public string $identifier;
    public bool $success = false;

    public static function generateOtp(): self {
        $self = new self();

        $response = Http::accept('application/json')
            ->post(self::$url . '/generate', [
                'digits'   => $self->digits,
                'validity' => $self->validity,
            ]);

        if ($response->status() === Response::HTTP_OK) {
            $self->identifier = $response['identifier'];
            $self->success = true;
        }

        return $self;
    }

    public static function validate(string $identifier, string $code = null): bool {
        if ($code) {
            $response = Http::accept('application/json')
                ->post(self::$url . '/validate', [
                    'identifier' => $identifier,
                    'code'       => $code,
                ]);
        } else {
            $response = Http::accept('application/json')
                ->post(self::$url . '/check-submitted', [
                    'identifier' => $identifier,
                ]);
        }

        return $response->status() === Response::HTTP_OK;
    }
}
