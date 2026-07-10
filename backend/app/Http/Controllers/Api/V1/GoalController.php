<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\CreateGoalRequest;
use App\Http\Requests\UpdateGoalRequest;
use App\Models\Block;
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
     *
     * Query params:
     * - category: filter by category slug
     * - scope: "mine" (default) or "browse" (other users' discoverable goals)
     */
    public function index(Request $request): JsonResponse
    {
        $category = $request->query('category');
        $scope = $request->query('scope', 'mine');

        if ($scope === 'browse') {
            return $this->success($this->browseGoals($request, $category));
        }

        $query = $request->user()->goals()->latest();

        if (is_string($category) && $category !== '') {
            $query->where('category', $category);
        }

        $goals = $query->get()->map(fn (Goal $goal) => $this->formatGoal($goal, true));

        return $this->success($goals);
    }

    /**
     * POST /api/v1/goals
     */
    public function store(CreateGoalRequest $request): JsonResponse
    {
        $goal = $request->user()->goals()->create($request->validated());

        return $this->success($this->formatGoal($goal->fresh(), true), null, 201);
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
     * @return list<array<string, mixed>>
     */
    private function browseGoals(Request $request, ?string $category): array
    {
        if (! is_string($category) || $category === '') {
            return [];
        }

        $userId = $request->user()->id;

        $blockedUserIds = Block::query()
            ->where('user_id', $userId)
            ->pluck('blocked_user_id')
            ->merge(
                Block::query()
                    ->where('blocked_user_id', $userId)
                    ->pluck('user_id')
            )
            ->unique()
            ->values();

        $goals = Goal::query()
            ->with('user:id,name,avatar_url')
            ->where('category', $category)
            ->where('user_id', '!=', $userId)
            ->when($blockedUserIds->isNotEmpty(), fn ($query) => $query->whereNotIn('user_id', $blockedUserIds))
            ->whereDoesntHave('podMembers', function ($query) {
                $query->whereNull('left_at')
                    ->whereHas('pod', fn ($podQuery) => $podQuery->where('status', 'active'));
            })
            ->whereHas('podRequests', fn ($query) => $query->where('status', 'open'))
            ->latest()
            ->get();

        return $goals
            ->map(fn (Goal $goal) => $this->formatGoal($goal, false))
            ->values()
            ->all();
    }

    /**
     * @return array<string, mixed>
     */
    private function formatGoal(Goal $goal, bool $isMine): array
    {
        $goal->loadMissing('user:id,name,avatar_url');

        return [
            'id' => $goal->id,
            'user_id' => $goal->user_id,
            'category' => $goal->category,
            'title' => $goal->title,
            'target_description' => $goal->target_description,
            'pace' => $goal->pace,
            'is_mine' => $isMine,
            'owner' => $goal->user ? [
                'id' => $goal->user->id,
                'name' => $goal->user->name,
                'avatar_url' => $goal->user->avatar_url,
            ] : null,
            'created_at' => $goal->created_at?->toIso8601String(),
        ];
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
