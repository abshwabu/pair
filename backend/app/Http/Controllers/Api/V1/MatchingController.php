<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\CreateMatchingRequest;
use App\Http\Requests\CreatePartnerMatchRequestRequest;
use App\Jobs\FindMatchJob;
use App\Models\Goal;
use App\Models\PartnerMatchRequest;
use App\Models\PodMember;
use App\Models\PodRequest;
use App\Services\BlockService;
use App\Services\PodMatchingService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;

class MatchingController extends Controller
{
    use ApiResponse;

    /**
     * POST /api/v1/matching/request
     */
    public function store(CreateMatchingRequest $request): JsonResponse
    {
        $user = $request->user();

        $hasOpenRequest = PodRequest::query()
            ->where('user_id', $user->id)
            ->where('status', 'open')
            ->exists();

        if ($hasOpenRequest) {
            return $this->error(
                'You already have an open matching request.',
                'open_request_exists',
                null,
                422
            );
        }

        $podRequest = PodRequest::create([
            'user_id' => $user->id,
            'goal_id' => $request->validated('goal_id'),
            'status' => 'open',
            'timezone_tolerance_hours' => $request->validated('timezone_tolerance_hours'),
            'language' => $user->language,
        ]);

        FindMatchJob::dispatch($podRequest->id);

        return $this->success([
            'id' => $podRequest->id,
            'status' => $podRequest->status,
            'pod_id' => null,
        ], null, 201);
    }

    /**
     * GET /api/v1/matching/request/{id}
     */
    public function show(PodRequest $podRequest): JsonResponse
    {
        Gate::authorize('view', $podRequest);

        $data = [
            'id' => $podRequest->id,
            'status' => $podRequest->status,
            'pod_id' => null,
        ];

        if ($podRequest->status === 'matched') {
            $data['pod_id'] = $this->podIdForRequest($podRequest);
        }

        return $this->success($data);
    }

    /**
     * DELETE /api/v1/matching/request/{id}
     */
    public function destroy(PodRequest $podRequest): JsonResponse
    {
        Gate::authorize('cancel', $podRequest);

        if ($podRequest->status !== 'open') {
            return $this->error(
                'Only open matching requests can be cancelled.',
                'request_not_open',
                null,
                422
            );
        }

        $podRequest->update(['status' => 'cancelled']);

        return $this->success([
            'id' => $podRequest->id,
            'status' => $podRequest->status,
        ]);
    }

    /**
     * GET /api/v1/matching/partner-requests
     */
    public function indexPartnerRequests(Request $request): JsonResponse
    {
        $direction = $request->query('direction', 'incoming');
        $userId = $request->user()->id;

        $query = PartnerMatchRequest::query()
            ->with([
                'requester:id,name,avatar_url',
                'recipient:id,name,avatar_url',
                'requesterGoal:id,title,target_description,pace,category',
                'recipientGoal:id,title,target_description,pace,category',
            ])
            ->latest();

        if ($direction === 'outgoing') {
            $query->where('requester_user_id', $userId);
        } else {
            $query->where('recipient_user_id', $userId);
        }

        if ($request->query('status') === 'pending') {
            $query->where('status', 'pending');
        }

        $requests = $query->get()->map(fn (PartnerMatchRequest $item) => $this->formatPartnerMatchRequest($item));

        return $this->success($requests);
    }

    /**
     * POST /api/v1/matching/partner-requests
     */
    public function storePartnerRequest(
        CreatePartnerMatchRequestRequest $request,
        BlockService $blockService,
        PodMatchingService $matcher,
    ): JsonResponse {
        $user = $request->user();
        $targetGoalId = $request->validated('target_goal_id');
        $ownGoalId = $request->validated('goal_id');

        if ($this->userHasActivePod($user->id)) {
            return $this->error(
                'Leave your current pod before sending a match request.',
                'already_in_pod',
                null,
                422
            );
        }

        $targetGoal = Goal::query()->with('user')->find($targetGoalId);
        $ownGoal = Goal::query()->where('id', $ownGoalId)->where('user_id', $user->id)->first();

        if (! $targetGoal || ! $ownGoal || $targetGoal->category !== $ownGoal->category) {
            return $this->error(
                'That goal is not available to match with.',
                'target_unavailable',
                null,
                422
            );
        }

        if ($this->userHasActivePod($targetGoal->user_id)) {
            return $this->error(
                'This partner is no longer available.',
                'target_unavailable',
                null,
                422
            );
        }

        if ($blockService->usersAreBlocked($user->id, $targetGoal->user_id)) {
            return $this->error(
                'You cannot match with this user.',
                'target_unavailable',
                null,
                422
            );
        }

        $recipientHasOpenRequest = PodRequest::query()
            ->where('user_id', $targetGoal->user_id)
            ->where('goal_id', $targetGoal->id)
            ->where('status', 'open')
            ->exists();

        if (! $recipientHasOpenRequest) {
            return $this->error(
                'This partner is not looking for a match right now.',
                'target_unavailable',
                null,
                422
            );
        }

        $hasPending = PartnerMatchRequest::query()
            ->where('requester_user_id', $user->id)
            ->where('recipient_goal_id', $targetGoal->id)
            ->where('status', 'pending')
            ->exists();

        if ($hasPending) {
            return $this->error(
                'You already sent a match request for this goal.',
                'request_already_sent',
                null,
                422
            );
        }

        $matcher->cancelOpenRequestsForUser($user->id);

        $partnerRequest = PartnerMatchRequest::create([
            'requester_user_id' => $user->id,
            'requester_goal_id' => $ownGoal->id,
            'recipient_user_id' => $targetGoal->user_id,
            'recipient_goal_id' => $targetGoal->id,
            'status' => 'pending',
            'timezone_tolerance_hours' => $request->validated('timezone_tolerance_hours'),
        ]);

        $partnerRequest->load([
            'requester:id,name,avatar_url',
            'recipient:id,name,avatar_url',
            'requesterGoal:id,title,target_description,pace,category',
            'recipientGoal:id,title,target_description,pace,category',
        ]);

        app(\App\Services\NotificationService::class)->send(
            $targetGoal->user,
            'match_request_received',
            [
                'partner_match_request_id' => $partnerRequest->id,
                'requester_id' => $user->id,
                'requester_name' => $user->name,
            ],
        );

        return $this->success($this->formatPartnerMatchRequest($partnerRequest), null, 201);
    }

    /**
     * GET /api/v1/matching/partner-requests/{partnerMatchRequest}
     */
    public function showPartnerRequest(PartnerMatchRequest $partnerMatchRequest): JsonResponse
    {
        Gate::authorize('view', $partnerMatchRequest);

        $partnerMatchRequest->load([
            'requester:id,name,avatar_url',
            'recipient:id,name,avatar_url',
            'requesterGoal:id,title,target_description,pace,category',
            'recipientGoal:id,title,target_description,pace,category',
        ]);

        return $this->success($this->formatPartnerMatchRequest($partnerMatchRequest));
    }

    /**
     * POST /api/v1/matching/partner-requests/{partnerMatchRequest}/accept
     */
    public function acceptPartnerRequest(
        PartnerMatchRequest $partnerMatchRequest,
        PodMatchingService $matcher,
    ): JsonResponse {
        Gate::authorize('accept', $partnerMatchRequest);

        if ($partnerMatchRequest->status !== 'pending') {
            return $this->error(
                'This match request is no longer pending.',
                'request_not_pending',
                null,
                422
            );
        }

        if ($this->userHasActivePod($partnerMatchRequest->requester_user_id)
            || $this->userHasActivePod($partnerMatchRequest->recipient_user_id)) {
            $partnerMatchRequest->update(['status' => 'cancelled']);

            return $this->error(
                'One of you is already in a pod.',
                'target_unavailable',
                null,
                422
            );
        }

        try {
            $pod = DB::transaction(function () use ($partnerMatchRequest, $matcher) {
                $pod = $matcher->acceptPartnerMatchRequest($partnerMatchRequest);

                $partnerMatchRequest->update([
                    'status' => 'accepted',
                    'pod_id' => $pod->id,
                ]);

                PartnerMatchRequest::query()
                    ->where('id', '!=', $partnerMatchRequest->id)
                    ->where('status', 'pending')
                    ->where(function ($query) use ($partnerMatchRequest) {
                        $query->where('requester_user_id', $partnerMatchRequest->requester_user_id)
                            ->orWhere('recipient_user_id', $partnerMatchRequest->recipient_user_id)
                            ->orWhere('requester_user_id', $partnerMatchRequest->recipient_user_id)
                            ->orWhere('recipient_user_id', $partnerMatchRequest->requester_user_id);
                    })
                    ->update(['status' => 'cancelled']);

                return $pod;
            });
        } catch (\RuntimeException) {
            return $this->error(
                'You are not compatible with this match request.',
                'incompatible_match',
                null,
                422
            );
        }

        $partnerMatchRequest->load([
            'requester:id,name,avatar_url',
            'recipient:id,name,avatar_url',
            'requesterGoal:id,title,target_description,pace,category',
            'recipientGoal:id,title,target_description,pace,category',
        ]);

        $data = $this->formatPartnerMatchRequest($partnerMatchRequest);
        $data['pod_id'] = $pod->id;

        return $this->success($data);
    }

    /**
     * POST /api/v1/matching/partner-requests/{partnerMatchRequest}/decline
     */
    public function declinePartnerRequest(PartnerMatchRequest $partnerMatchRequest): JsonResponse
    {
        Gate::authorize('decline', $partnerMatchRequest);

        if ($partnerMatchRequest->status !== 'pending') {
            return $this->error(
                'This match request is no longer pending.',
                'request_not_pending',
                null,
                422
            );
        }

        $partnerMatchRequest->update(['status' => 'declined']);

        $partnerMatchRequest->load('requester');

        app(\App\Services\NotificationService::class)->send(
            $partnerMatchRequest->requester,
            'match_request_declined',
            [
                'partner_match_request_id' => $partnerMatchRequest->id,
            ],
        );

        return $this->success($this->formatPartnerMatchRequest($partnerMatchRequest->fresh([
            'requester:id,name,avatar_url',
            'recipient:id,name,avatar_url',
            'requesterGoal:id,title,target_description,pace,category',
            'recipientGoal:id,title,target_description,pace,category',
        ])));
    }

    /**
     * DELETE /api/v1/matching/partner-requests/{partnerMatchRequest}
     */
    public function cancelPartnerRequest(PartnerMatchRequest $partnerMatchRequest): JsonResponse
    {
        Gate::authorize('cancel', $partnerMatchRequest);

        if ($partnerMatchRequest->status !== 'pending') {
            return $this->error(
                'Only pending match requests can be cancelled.',
                'request_not_pending',
                null,
                422
            );
        }

        $partnerMatchRequest->update(['status' => 'cancelled']);

        return $this->success($this->formatPartnerMatchRequest($partnerMatchRequest->fresh([
            'requester:id,name,avatar_url',
            'recipient:id,name,avatar_url',
            'requesterGoal:id,title,target_description,pace,category',
            'recipientGoal:id,title,target_description,pace,category',
        ])));
    }

    /**
     * @return array<string, mixed>
     */
    private function formatPartnerMatchRequest(PartnerMatchRequest $request): array
    {
        return [
            'id' => $request->id,
            'status' => $request->status,
            'pod_id' => $request->pod_id,
            'timezone_tolerance_hours' => $request->timezone_tolerance_hours,
            'requester' => $request->requester ? [
                'id' => $request->requester->id,
                'name' => $request->requester->name,
                'avatar_url' => $request->requester->avatar_url,
            ] : null,
            'recipient' => $request->recipient ? [
                'id' => $request->recipient->id,
                'name' => $request->recipient->name,
                'avatar_url' => $request->recipient->avatar_url,
            ] : null,
            'requester_goal' => $request->requesterGoal ? [
                'id' => $request->requesterGoal->id,
                'title' => $request->requesterGoal->title,
                'target_description' => $request->requesterGoal->target_description,
                'pace' => $request->requesterGoal->pace,
                'category' => $request->requesterGoal->category,
            ] : null,
            'recipient_goal' => $request->recipientGoal ? [
                'id' => $request->recipientGoal->id,
                'title' => $request->recipientGoal->title,
                'target_description' => $request->recipientGoal->target_description,
                'pace' => $request->recipientGoal->pace,
                'category' => $request->recipientGoal->category,
            ] : null,
            'created_at' => $request->created_at?->toIso8601String(),
        ];
    }

    private function podIdForRequest(PodRequest $podRequest): ?string
    {
        return PodMember::query()
            ->where('user_id', $podRequest->user_id)
            ->where('goal_id', $podRequest->goal_id)
            ->whereHas('pod', fn ($query) => $query->where('status', 'active'))
            ->value('pod_id');
    }

    private function userHasActivePod(string $userId): bool
    {
        return PodMember::query()
            ->where('user_id', $userId)
            ->whereNull('left_at')
            ->whereHas('pod', fn ($query) => $query->where('status', 'active'))
            ->exists();
    }
}
