<?php

namespace Shared;

use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\ServiceProvider;
use Shared\Commands\UpdateConfigsCommand;
use Shared\Commands\UpdateHostnameCommand;
use Shared\Middleware\AuthServerMiddleware;
use Shared\Middleware\ForceJsonMiddleware;

class SharedServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     *
     * @return void
     */
    public function register()
    {
        //
    }

    /**
     * Bootstrap any application services.
     *
     * @return void
     */
    public function boot(): void
    {
        $this->registerCommands();

        $this->loadRoutesFrom(__DIR__ . '/routes/api.php');

        $router = $this->app['router'];

        $router->aliasMiddleware('json', ForceJsonMiddleware::class);
        $router->aliasMiddleware('auth.server', AuthServerMiddleware::class);

        if (ConfigClient::$runEveryTime) {
            self::updateEnvConfigs(false);
        }

        Auth::extend('json', function ($app, $name, array $config) {
            return new JsonGuard(Auth::createUserProvider($config['provider']), $app->make('request'));
        });

        Config::set('database.connections.db_shared', [
            'driver' => env('DB_SHARED_CONNECTION', 'mysql'),
            'host' => env('DB_SHARED_HOST', '127.0.0.1'),
            'port' => env('DB_SHARED_PORT', '3306'),
            'database' => env('DB_SHARED_DATABASE', 'phober_shared'),
            'username' => env('DB_SHARED_USERNAME', 'forge'),
            'password' => env('DB_SHARED_PASSWORD', ''),
        ]);
    }

    /**
     * Register the package's commands.
     *
     * @return void
     */
    protected function registerCommands(): void
    {
        $this->commands([
            UpdateHostnameCommand::class,
            UpdateConfigsCommand::class,
        ]);
    }

    /**
     * @param bool $dryRun
     * @return void
     * @link https://github.com/vlucas/phpdotenv
     */
    public static function updateEnvConfigs(bool $dryRun): void
    {
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
    private static function setEnvironmentValue(array $values, $dryRun): void
    {
        $envFile = ConfigClient::$customEnvFile ?? app()->environmentFilePath();
        ConfigClient::$newConfigCount = 0;
        ConfigClient::$updatedConfigCount = 0;

        if (!file_exists($envFile)) {
            file_put_contents($envFile, '');
        }

        $str = file_get_contents($envFile);

        if (count($values) > 0) {
            foreach ($values as $envKey => $envValue) {
                $keyPosition = strpos($str, "{$envKey}=");
                $endOfLinePosition = strpos($str, "\n", $keyPosition);
                $oldLine = substr($str, $keyPosition, $endOfLinePosition - $keyPosition);

                if (str_contains($envValue, ' ')) {
                    $envValue = "\"$envValue\"";
                }

                // If key does not exist, add it
                if (!$keyPosition || !$endOfLinePosition || !$oldLine) {
                    $str .= "{$envKey}={$envValue}\n";
                    ConfigClient::$newConfigCount++;
                } else if (ConfigClient::$overwrite && ($newLine = "{$envKey}={$envValue}") && $oldLine != $newLine) {
                    $str = str_replace($oldLine, $newLine, $str);
                    ConfigClient::$updatedConfigCount++;
                }
            }

            $str .= "\n"; // In case the searched variable is in the last line without \n
        }

        $str = substr($str, 0, -1);

        $dryRun || file_put_contents($envFile, $str) !== false;
    }
}