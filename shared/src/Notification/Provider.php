<?php

namespace Shared\Notification;

enum Provider: string {
    case DISCORD = 'DISCORD';
    case TELEGRAM = 'TELEGRAM';
}
