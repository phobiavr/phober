<?php

namespace Shared\Clients;

abstract class Client implements ClientInterface
{
    protected static ?string $url = null;
}
