<?php

namespace Shared\Clients;

use Illuminate\Support\Facades\Http;
use Shared\Notification\Channel;
use Shared\Notification\Provider;

class NotificationClient {
    protected static ?string $url = 'http://notification-server';

    public static function sendMessage(Provider $provider, Channel $channel, string $message): void {
        Http::accept('application/json')->post(self::$url . '/', [
            'provider' => $provider->value,
            'channel'  => $channel->value,
            'message'  => $message,
        ]);
    }
}
