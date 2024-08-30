<?php

namespace Shared\Enums;

enum SessionTimeEnum: string {
    case MIN_15 = 'MIN_15';
    case MIN_30 = 'MIN_30';
    case MIN_60 = 'MIN_60';

    public function getMins(): int {
        return match ($this) {
            self::MIN_15 => 15,
            self::MIN_30 => 30,
            self::MIN_60 => 60,
        };
    }
}
