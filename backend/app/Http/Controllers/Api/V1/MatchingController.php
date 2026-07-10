<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\CreateMatchingRequest;
use App\Jobs\FindMatchJob;
use App\Models\PodMember;
use App\Models\PodRequest;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
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
            $data['pod_id'] = PodMember::query()
                ->where('user_id', $podRequest->user_id)
                ->where('goal_id', $podRequest->goal_id)
                ->whereHas('pod', fn ($query) => $query->where('status', 'active'))
                ->value('pod_id');
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
}
