<?php

namespace App\Jobs;

use App\Jobs\FindMatchJob;
use App\Models\Pod;
use App\Models\PodMember;
use App\Models\PodRequest;
use App\Services\BlockService;
use App\Services\MatchingScorer;
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

    public function handle(MatchingScorer $scorer, BlockService $blockService): void
    {
        DB::transaction(function () use ($scorer, $blockService) {
            $request = PodRequest::query()
                ->with(['goal', 'user'])
                ->lockForUpdate()
                ->find($this->podRequestId);

            if (! $request || $request->status !== 'open') {
                return;
            }

            $candidates = PodRequest::query()
                ->with(['goal', 'user'])
                ->where('status', 'open')
                ->where('id', '!=', $request->id)
                ->where('user_id', '!=', $request->user_id)
                ->lockForUpdate()
                ->get();

            $bestCandidate = null;
            $bestScore = 0;

            foreach ($candidates as $candidate) {
                if ($blockService->usersAreBlocked($request->user_id, $candidate->user_id)) {
                    continue;
                }

                $score = $scorer->score($request, $candidate);

                if ($scorer->meetsThreshold($score) && $score > $bestScore) {
                    $bestScore = $score;
                    $bestCandidate = $candidate;
                }
            }

            if ($bestCandidate) {
                $this->createMatch($request, $bestCandidate);

                return;
            }

            $this->requeueIfNeeded();
        });
    }

    private function createMatch(PodRequest $request, PodRequest $candidate): void
    {
        $pod = Pod::create([
            'goal_category' => $request->goal->category,
            'status' => 'active',
            'capacity' => 2,
        ]);

        $now = now();

        PodMember::create([
            'pod_id' => $pod->id,
            'user_id' => $request->user_id,
            'goal_id' => $request->goal_id,
            'joined_at' => $now,
        ]);

        PodMember::create([
            'pod_id' => $pod->id,
            'user_id' => $candidate->user_id,
            'goal_id' => $candidate->goal_id,
            'joined_at' => $now,
        ]);

        $request->update(['status' => 'matched']);
        $candidate->update(['status' => 'matched']);
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
