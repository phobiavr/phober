<?php

namespace Shared;

use Illuminate\Support\ServiceProvider;
use Shared\Commands\UpdateHostnameCommand;
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
        ]);
    }
}