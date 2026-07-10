<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Pod;
use App\Services\PodMembershipService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class PodController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly PodMembershipService $podMembershipService) {}

    /**
     * GET /api/v1/pods
     */
    public function index(Request $request): JsonResponse
    {
        $pods = Pod::query()
            ->whereHas('podMembers', function ($query) use ($request) {
                $query->where('user_id', $request->user()->id)
                    ->whereNull('left_at');
            })
            ->orderByDesc('created_at')
            ->get();

        return $this->success($pods);
    }

    /**
     * GET /api/v1/pods/{id}
     */
    public function show(Pod $pod): JsonResponse
    {
        Gate::authorize('view', $pod);

        $pod->load(['podMembers.user', 'podMembers.goal', 'streak']);

        return $this->success([
            'id' => $pod->id,
            'goal_category' => $pod->goal_category,
            'status' => $pod->status,
            'capacity' => $pod->capacity,
            'members' => $pod->podMembers->map(fn ($member) => [
                'user' => [
                    'id' => $member->user->id,
                    'name' => $member->user->name,
                    'avatar_url' => $member->user->avatar_url,
                ],
                'goal' => $member->goal,
                'joined_at' => $member->joined_at,
                'left_at' => $member->left_at,
            ])->values(),
            'streak' => $pod->streak ? [
                'current_streak' => $pod->streak->current_streak,
                'best_streak' => $pod->streak->best_streak,
                'last_check_in_date' => $pod->streak->last_check_in_date?->toDateString(),
            ] : null,
        ]);
    }

    /**
     * POST /api/v1/pods/{id}/leave
     */
    public function leave(Request $request, Pod $pod): JsonResponse
    {
        Gate::authorize('leave', $pod);

        $membership = $pod->podMembers()
            ->where('user_id', $request->user()->id)
            ->whereNull('left_at')
            ->firstOrFail();

        $this->podMembershipService->leave($pod, $request->user());

        $pod->refresh();
        $membership->refresh();

        return $this->success([
            'pod_id' => $pod->id,
            'status' => $pod->status,
            'left_at' => $membership->left_at,
        ]);
    }
}
