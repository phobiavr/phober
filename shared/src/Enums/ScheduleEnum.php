<?php

namespace Shared\Enums;

enum ScheduleEnum: string {
    case MAINTENANCE = 'MAINTENANCE';
    case RESERVATION = 'RESERVATION';
    case INSPECTION = 'INSPECTION';
    case REPAIR = 'REPAIR';
    case IN_USE = 'IN_USE';
    case IN_SESSION = 'IN_SESSION';
    case ON_EVENT = 'ON_EVENT';
}
