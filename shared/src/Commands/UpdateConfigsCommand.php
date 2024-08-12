<?php

namespace Shared\Commands;

use Illuminate\Console\Command;
use Shared\ConfigClient;

class UpdateConfigsCommand extends Command
{
  protected $signature = 'config-client:update
                            {--dry-run : Simulate the update process without making any changes}
                            {--custom-env-file= : Specify a custom .env file for the update}
                            {--overwrite : Overwrite existing .env configurations with new values}';

  protected $description = 'Update all .env values from the config server. Use --dry-run to simulate the update process.';

  /**
   * Execute the console command.
   *
   * @return void
   */
  public function handle(): void
  {
    if ($customEnvFile = $this->option('custom-env-file')) {
      ConfigClient::$customEnvFile = $customEnvFile;
    } else {
      ConfigClient::$customEnvFile = '.env.shared';
    }

    if ($this->option('overwrite')) {
      ConfigClient::$overwrite = true;
    }

    if ($this->option('dry-run')) {
      $this->info('Simulating update process...');
      ConfigClient::update(true);
      $this->displayUpdateResults(ConfigClient::$newConfigCount, ConfigClient::$updatedConfigCount);
      $this->info('Dry run completed. No actual changes were made.');
    } else {
      ConfigClient::update();
      $this->displayUpdateResults(ConfigClient::$newConfigCount, ConfigClient::$updatedConfigCount);
    }
  }

  /**
   * Display the results of the update.
   *
   * @param int $newConfigCount Number of new configurations added.
   * @param int $updatedConfigCount Number of configurations updated.
   * @return void
   */
  private function displayUpdateResults(int $newConfigCount, int $updatedConfigCount): void
  {
    $this->info("Number of new .env configurations added: <fg=yellow>{$newConfigCount}</>");
    $this->info("Number of .env configurations updated: <fg=yellow>{$updatedConfigCount}</>");
  }
}
