<?php

namespace Shared\Enums;

enum InvoiceStatusEnum: string {
    case QUEUE = 'QUEUE';
    case PAYED = 'PAYED';
    case CANCELED = 'CANCELED';
}
