<?php

namespace Shared\Clients;

class ConfigClient {
    public static bool $overwrite = false;
    public static bool $runEveryTime = false;
    public static int $newConfigCount = 0;
    public static int $updatedConfigCount = 0;
    public static ?string $customEnvFile = null;

    public static function runEveryTime(): void {
        self::$runEveryTime = true;
    }

    public static function overwriteExistingValues(): void {
        self::$overwrite = true;
    }

    public static function update(bool $dryRun = false): void {
        \Shared\SharedServiceProvider::updateEnvConfigs($dryRun);
    }
}
