<?php

namespace App\Services;

use App\Models\Goal;
use App\Models\PartnerMatchRequest;
use App\Models\Pod;
use App\Models\PodMember;
use App\Models\PodRequest;
use App\Models\User;

class PodMatchingService
{
    public function __construct(
        private MatchingScorer $scorer,
        private BlockService $blockService,
        private NotificationService $notificationService,
    ) {}

    /**
     * Try to match an open request with the best available candidate.
     */
    public function tryMatchRequest(PodRequest $request): bool
    {
        $request->loadMissing(['goal', 'user']);

        if ($request->status !== 'open') {
            return false;
        }

        if ($this->isReservedForPartnerRequest($request)) {
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
            if ($this->isReservedForPartnerRequest($candidate)) {
                continue;
            }

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

    /**
     * Users waiting on a directed partner request must not be auto-matched.
     */
    public function isReservedForPartnerRequest(PodRequest $request): bool
    {
        $hasPendingIncoming = PartnerMatchRequest::query()
            ->where('recipient_user_id', $request->user_id)
            ->where('recipient_goal_id', $request->goal_id)
            ->where('status', 'pending')
            ->exists();

        if ($hasPendingIncoming) {
            return true;
        }

        return PartnerMatchRequest::query()
            ->where('requester_user_id', $request->user_id)
            ->where('status', 'pending')
            ->exists();
    }

    public function cancelOpenRequestsForUser(string $userId): void
    {
        PodRequest::query()
            ->where('user_id', $userId)
            ->where('status', 'open')
            ->update(['status' => 'cancelled']);
    }

    public function canPair(PodRequest $request, PodRequest $candidate): bool
    {
        if ($this->blockService->usersAreBlocked($request->user_id, $candidate->user_id)) {
            return false;
        }

        $score = $this->scorer->score($request, $candidate);

        return $this->scorer->meetsThreshold($score);
    }

    /**
     * Accept a directed partner match request and create a pod.
     */
    public function acceptPartnerMatchRequest(PartnerMatchRequest $partnerRequest): Pod
    {
        $partnerRequest->loadMissing([
            'requester',
            'recipient',
            'requesterGoal',
            'recipientGoal',
        ]);

        $recipientRequest = $this->podRequestForPartnerUser(
            userId: $partnerRequest->recipient_user_id,
            goalId: $partnerRequest->recipient_goal_id,
            timezoneToleranceHours: $partnerRequest->timezone_tolerance_hours,
            user: $partnerRequest->recipient,
            goal: $partnerRequest->recipientGoal,
        );

        $requesterRequest = $this->podRequestForPartnerUser(
            userId: $partnerRequest->requester_user_id,
            goalId: $partnerRequest->requester_goal_id,
            timezoneToleranceHours: $partnerRequest->timezone_tolerance_hours,
            user: $partnerRequest->requester,
            goal: $partnerRequest->requesterGoal,
        );

        if (! $this->canPair($requesterRequest, $recipientRequest)) {
            throw new \RuntimeException('incompatible_match');
        }

        return $this->createMatch($requesterRequest, $recipientRequest);
    }

    private function podRequestForPartnerUser(
        string $userId,
        string $goalId,
        int $timezoneToleranceHours,
        User $user,
        Goal $goal,
    ): PodRequest {
        $existing = PodRequest::query()
            ->with(['goal', 'user'])
            ->where('user_id', $userId)
            ->where('goal_id', $goalId)
            ->where('status', 'open')
            ->first();

        if ($existing) {
            return $existing;
        }

        $request = new PodRequest([
            'user_id' => $userId,
            'goal_id' => $goalId,
            'status' => 'open',
            'timezone_tolerance_hours' => $timezoneToleranceHours,
            'language' => $user->language,
        ]);
        $request->setRelation('goal', $goal);
        $request->setRelation('user', $user);

        return $request;
    }

    public function createMatch(PodRequest $request, PodRequest $candidate): Pod
    {
        $request->loadMissing(['goal', 'user']);
        $candidate->loadMissing(['goal', 'user']);

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

        if ($request->exists) {
            $request->update(['status' => 'matched']);
        } else {
            PodRequest::query()
                ->where('user_id', $request->user_id)
                ->where('status', 'open')
                ->update(['status' => 'cancelled']);
        }

        if ($candidate->exists) {
            $candidate->update(['status' => 'matched']);
        } else {
            PodRequest::query()
                ->where('user_id', $candidate->user_id)
                ->where('status', 'open')
                ->update(['status' => 'cancelled']);
        }

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
