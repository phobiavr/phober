<?php

namespace Shared\Package\Commands\Console;

use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class UpdateHostnameCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'hostname:update {container}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Updates or creates a hostname record';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $hostname = gethostname(); // Automatically get the hostname
        $containerName = $this->argument('container'); // Manually provided container name
        $timestamp = Carbon::now();
        $success = false;

        while (!$success) {
            try {
                $query = DB::connection('db_log')->table('hostnames');
                $record = [
                    'container' => $containerName,
                    'updated_at' => $timestamp,
                ];

                if ($query->where('hostname', $hostname)->exists()) {
                    $query->where('hostname', $hostname)
                        ->update($record);

                    $this->info("Hostname record for '{$hostname}' has been updated.");
                } else {
                    $query->insert([
                            'hostname' => $hostname,
                            'created_at' => $timestamp,
                        ] + $record);

                    $this->info("Hostname record for '{$hostname}' has been created.");
                }

                $success = true;
            } catch (\Exception $e) {
                $this->error("Failed to update or create hostname record: {$e->getMessage()}. Retrying in 1 second...");
                sleep(1);
            }
        }

        return Command::SUCCESS;
    }
}
