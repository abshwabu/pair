<?php

namespace App\Console\Commands;

use App\Jobs\FindMatchJob;
use App\Models\PodRequest;
use Illuminate\Console\Command;

class SweepUnmatchedPodRequests extends Command
{
    protected $signature = 'matching:sweep';

    protected $description = 'Retry open pod matching requests older than 2 minutes';

    public function handle(): int
    {
        $staleRequests = PodRequest::query()
            ->where('status', 'open')
            ->where('created_at', '<=', now()->subMinutes(2))
            ->pluck('id');

        foreach ($staleRequests as $podRequestId) {
            FindMatchJob::dispatch($podRequestId);
        }

        $this->info("Dispatched matching jobs for {$staleRequests->count()} open request(s).");

        return self::SUCCESS;
    }
}
