<?php

namespace App\Jobs;

use App\Models\PodRequest;
use App\Services\PodMatchingService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\DB;

class FindMatchJob implements ShouldQueue
{
    use Queueable;

    public const MAX_ATTEMPTS = 5;

    private const BASE_DELAY_SECONDS = 60;

    public function __construct(
        public string $podRequestId,
        public int $attempt = 1,
    ) {}

    public function handle(PodMatchingService $matcher): void
    {
        DB::transaction(function () use ($matcher) {
            $request = PodRequest::query()
                ->with(['goal', 'user'])
                ->lockForUpdate()
                ->find($this->podRequestId);

            if (! $request || $request->status !== 'open') {
                return;
            }

            if ($matcher->tryMatchRequest($request)) {
                return;
            }

            $this->requeueIfNeeded();
        });
    }

    private function requeueIfNeeded(): void
    {
        if ($this->attempt >= self::MAX_ATTEMPTS) {
            return;
        }

        $delaySeconds = self::BASE_DELAY_SECONDS * (2 ** ($this->attempt - 1));

        self::dispatch($this->podRequestId, $this->attempt + 1)
            ->delay(now()->addSeconds($delaySeconds));
    }
}
