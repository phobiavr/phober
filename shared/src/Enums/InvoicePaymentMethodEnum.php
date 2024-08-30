<?php

namespace Shared\Enums;

enum InvoicePaymentMethodEnum: string {
    case CASH = 'CASH';
    case CARD = 'CARD';
    case BONUS = 'BONUS';
}
