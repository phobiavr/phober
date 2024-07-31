<?php

namespace Shared\Package;

use Illuminate\Support\ServiceProvider;
use Shared\Package\Commands\Console\UpdateHostnameCommand;

class PackageProvider extends ServiceProvider
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