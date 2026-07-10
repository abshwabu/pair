<?php

namespace App\Services;

use App\Models\Pod;
use App\Models\PodMember;
use App\Models\PodRequest;

class PodMatchingService
{
    public function __construct(
        private MatchingScorer $scorer,
        private BlockService $blockService,
        private NotificationService $notificationService,
    ) {}

    /**
     * Try to match an open request, optionally preferring a specific goal's request.
     */
    public function tryMatchRequest(PodRequest $request, ?string $preferredGoalId = null): bool
    {
        $request->loadMissing(['goal', 'user']);

        if ($request->status !== 'open') {
            return false;
        }

        if ($preferredGoalId !== null) {
            $preferred = PodRequest::query()
                ->with(['goal', 'user'])
                ->where('goal_id', $preferredGoalId)
                ->where('status', 'open')
                ->where('user_id', '!=', $request->user_id)
                ->first();

            if ($preferred && $this->canPair($request, $preferred)) {
                $this->createMatch($request, $preferred);

                return true;
            }

            return false;
        }

        $candidates = PodRequest::query()
            ->with(['goal', 'user'])
            ->where('status', 'open')
            ->where('id', '!=', $request->id)
            ->where('user_id', '!=', $request->user_id)
            ->get();

        $bestCandidate = null;
        $bestScore = 0;

        foreach ($candidates as $candidate) {
            if ($this->blockService->usersAreBlocked($request->user_id, $candidate->user_id)) {
                continue;
            }

            $score = $this->scorer->score($request, $candidate);

            if ($this->scorer->meetsThreshold($score) && $score > $bestScore) {
                $bestScore = $score;
                $bestCandidate = $candidate;
            }
        }

        if ($bestCandidate) {
            $this->createMatch($request, $bestCandidate);

            return true;
        }

        return false;
    }

    public function canPair(PodRequest $request, PodRequest $candidate): bool
    {
        if ($this->blockService->usersAreBlocked($request->user_id, $candidate->user_id)) {
            return false;
        }

        $score = $this->scorer->score($request, $candidate);

        return $this->scorer->meetsThreshold($score);
    }

    public function createMatch(PodRequest $request, PodRequest $candidate): Pod
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

        $this->notificationService->send($request->user, 'match_found', [
            'pod_id' => $pod->id,
            'partner_id' => $candidate->user_id,
        ]);

        $this->notificationService->send($candidate->user, 'match_found', [
            'pod_id' => $pod->id,
            'partner_id' => $request->user_id,
        ]);

        return $pod;
    }
}
