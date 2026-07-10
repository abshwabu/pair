<?php

namespace App\Console\Commands;

use App\Services\StreakService;
use Illuminate\Console\Command;

class ResetMissedStreaks extends Command
{
    protected $signature = 'streaks:reset-missed';

    protected $description = 'Reset pod streaks when the last full check-in day is older than yesterday (UTC)';

    public function handle(StreakService $streakService): int
    {
        $resetCount = $streakService->resetMissedStreaks();

        $this->info("Reset current streak for {$resetCount} pod(s).");

        return self::SUCCESS;
    }
}
