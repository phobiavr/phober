<?php

use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Route;
use Shared\ConfigClient;

Route::get('/instance-info', function () {
    return response()->json([
        'instance_id' => gethostname(),
    ]);
});

Route::prefix('/config-client')->group(function () {
    Route::get('/update', function () {
        $dryRun = request()->query('dry-run', false) === 'true'; // Ensure boolean conversion
        $overwrite = request()->query('overwrite', false) === 'true'; // Ensure boolean conversion
        $envFile = request()->query('env-file', null);

        $command = 'config-client:update';
        $parameters = [
            '--dry-run' => $dryRun,
            '--overwrite' => $overwrite,
        ];

        if ($envFile) {
            $parameters['--custom-env-file'] = $envFile;
        }

        Artisan::call($command, $parameters);

        return response()->json([
            'message' => 'Config update command executed.',
            'options' => [
                'dry_run' => $dryRun,
                'overwrite' => $overwrite,
                'custom_env_file' => $envFile ?: 'Default',
            ],
            'results' => [
                'new_configurations_added' => ConfigClient::$newConfigCount,
                'configurations_updated' => ConfigClient::$updatedConfigCount,
            ],
        ]);
    });
});