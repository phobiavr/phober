<?php

namespace Shared\Clients;

use Illuminate\Http\Response;
use Illuminate\Support\Facades\Http;

class OtpClient implements ClientInterface {
    protected static ?string $url = null;
    public int $digits = 4;
    public int $validity = 10;
    public string $identifier;
    public string $code;
    public bool $success = false;

    public static function getUrl(): string {
        return static::$url ??= env('AUTH_SERVER', 'http://auth-server') . '/otp';
    }

    public static function generateOtp(): self {
        $self = new self();
        $self->identifier = gethostname() . '-' . \Shared\Helper::quickRandom(5);

        $response = Http::accept('application/json')
            ->post(self::getUrl() . '/generate', [
                'identifier' => $self->identifier,
                'digits'     => $self->digits,
                'validity'   => $self->validity,
            ]);

        if ($response->status() === Response::HTTP_OK) {
            $self->code = $response['code'];
            $self->success = true;
        }

        return $self;
    }

    public static function validate(string $identifier, string $code = null): bool {
        if ($code) {
            $response = Http::accept('application/json')
                ->post(self::getUrl() . '/validate', [
                    'identifier' => $identifier,
                    'code'       => $code,
                ]);
        } else {
            $response = Http::accept('application/json')
                ->post(self::getUrl() . '/check-submitted', [
                    'identifier' => $identifier,
                ]);
        }

        return $response->status() === Response::HTTP_OK;
    }
}
