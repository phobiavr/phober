<?php

namespace Shared\Clients;

use Illuminate\Support\Facades\Http;

class ConfigClient implements ClientInterface {
    protected static ?string $url = null;

    public static function getUrl(): string {
        return static::$url ??= env('CONFIG_SERVER', 'http://config-server');
    }

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

    /**
     * @param bool $dryRun
     * @return void
     * @link https://github.com/vlucas/phpdotenv
     */
    public static function update(bool $dryRun): void {
        $server = env('CONFIG_SERVER', 'http://config-server');

        $response = Http::get($server);

        if ($response->ok()) {
            self::setEnvironmentValue($response->json(), $dryRun);
        }
    }

    /**
     * @param array $values
     * @param $dryRun
     * @return void
     * @link https://stackoverflow.com/a/54173207
     */
    private static function setEnvironmentValue(array $values, $dryRun): void {
        $envFile = ConfigClient::$customEnvFile ?? app()->environmentFilePath();
        ConfigClient::$newConfigCount = 0;
        ConfigClient::$updatedConfigCount = 0;
        $hasChanges = false;

        if (!file_exists($envFile)) {
            file_put_contents($envFile, '');
        }

        $str = file_get_contents($envFile);

        if (count($values) > 0) {
            foreach ($values as $envKey => $envValue) {
                if (str_contains($envValue, ' ')) {
                    $envValue = "\"$envValue\"";
                }

                $keyPosition = strpos($str, "{$envKey}=");

                // If key does not exist, add it
                if ($keyPosition === false) {
                    $str .= "{$envKey}={$envValue}\n";
                    ConfigClient::$newConfigCount++;
                    $hasChanges = true;
                } else {
                    $endOfLinePosition = strpos($str, "\n", $keyPosition);
                    $oldLine = substr($str, $keyPosition, $endOfLinePosition - $keyPosition);

                    $newLine = "{$envKey}={$envValue}";

                    if (ConfigClient::$overwrite && $oldLine != $newLine) {
                        $str = str_replace($oldLine, $newLine, $str);
                        ConfigClient::$updatedConfigCount++;
                        $hasChanges = true;
                    }
                }
            }

            if ($hasChanges && !str_ends_with($str, "\n")) {
                $str .= "\n";
            }
        }

        $dryRun || file_put_contents($envFile, $str) !== false;
    }
}