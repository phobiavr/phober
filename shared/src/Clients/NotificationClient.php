<?php

namespace Shared\Clients;

use Illuminate\Support\Facades\Http;
use Shared\Notification\Channel;
use Shared\Notification\Provider;

class NotificationClient extends Client {
    public static function getUrl(): string {
        return static::$url ??= env('NOTIFICATION_SERVER', 'http://notification-server');
    }

    public static function sendMessage(Provider $provider, Channel $channel, string $message): void {
        Http::accept('application/json')->post(self::getUrl() . '/', [
            'provider' => $provider->value,
            'channel'  => $channel->value,
            'message'  => $message,
        ]);
    }
}
