<?php

namespace Shared\Enums;

enum SessionStatusEnum: string {
    case QUEUE = 'QUEUE';
    case ACTIVE = 'ACTIVE';
    case CANCELED = 'CANCELED';
    case FINISHED = 'FINISHED';
}
