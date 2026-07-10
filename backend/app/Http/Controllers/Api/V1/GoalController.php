<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\CreateGoalRequest;
use App\Http\Requests\UpdateGoalRequest;
use App\Models\Goal;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class GoalController extends Controller
{
    use ApiResponse;

    /**
     * GET /api/v1/goals
     */
    public function index(Request $request): JsonResponse
    {
        $goals = $request->user()->goals()->get();
        return $this->success($goals);
    }

    /**
     * POST /api/v1/goals
     */
    public function store(CreateGoalRequest $request): JsonResponse
    {
        $goal = $request->user()->goals()->create($request->validated());
        return $this->success($goal, null, 201);
    }

    /**
     * GET /api/v1/goals/{id}
     */
    public function show(Goal $goal): JsonResponse
    {
        Gate::authorize('view', $goal);
        return $this->success($goal);
    }

    /**
     * PATCH /api/v1/goals/{id}
     */
    public function update(UpdateGoalRequest $request, Goal $goal): JsonResponse
    {
        Gate::authorize('update', $goal);

        // Check if goal is attached to an active pod
        if ($this->isAttachedToActivePod($goal)) {
            return $this->error(
                'Cannot update a goal that is already attached to an active pod.',
                'goal_attached_to_active_pod',
                null,
                422
            );
        }

        $goal->update($request->validated());

        return $this->success($goal);
    }

    /**
     * DELETE /api/v1/goals/{id}
     */
    public function destroy(Goal $goal): JsonResponse
    {
        Gate::authorize('delete', $goal);

        // Check if goal is attached to an active pod
        if ($this->isAttachedToActivePod($goal)) {
            return $this->error(
                'Cannot delete a goal that is already attached to an active pod.',
                'goal_attached_to_active_pod',
                null,
                422
            );
        }

        $goal->delete();

        return $this->success(['message' => 'Goal deleted successfully.']);
    }

    /**
     * Check if the goal is linked to any pod with an 'active' status.
     */
    private function isAttachedToActivePod(Goal $goal): bool
    {
        return $goal->podMembers()
            ->whereHas('pod', function ($query) {
                $query->where('status', 'active');
            })
            ->exists();
    }
}
