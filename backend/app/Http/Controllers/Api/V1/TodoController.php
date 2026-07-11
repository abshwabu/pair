<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\CreateTodoRequest;
use App\Http\Requests\UpdateTodoRequest;
use App\Models\Pod;
use App\Models\Todo;
use App\Models\TodoCompletion;
use App\Services\NotificationService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class TodoController extends Controller
{
    use ApiResponse;

    /**
     * GET /api/v1/pods/{pod}/todos
     */
    public function index(Request $request, Pod $pod): JsonResponse
    {
        Gate::authorize('view', $pod);

        $query = $pod->todos()->with('completions');

        if ($request->has('assigned_to')) {
            $assignedTo = $request->query('assigned_to');

            if ($assignedTo === 'null' || $assignedTo === '') {
                $query->whereNull('assigned_to');
            } else {
                $query->where('assigned_to', $assignedTo);
            }
        }

        if ($request->query('status')) {
            $query->where('status', $request->query('status'));
        }

        $sortDirection = strtolower($request->query('sort_direction', 'asc')) === 'desc' ? 'desc' : 'asc';
        $query->orderBy('due_date', $sortDirection);

        $todos = $query->get()->map(
            fn (Todo $todo) => $this->formatTodo($todo, $request->user())
        );

        return $this->success($todos);
    }

    /**
     * POST /api/v1/pods/{pod}/todos
     */
    public function store(CreateTodoRequest $request, Pod $pod): JsonResponse
    {
        Gate::authorize('view', $pod);

        $userId = $request->user()->id;
        $validated = $request->validated();
        $assignedTo = $validated['assigned_to'] ?? null;
        $status = $assignedTo === $userId ? Todo::STATUS_ACTIVE : Todo::STATUS_PENDING;

        $todo = $pod->todos()->create([
            ...$validated,
            'created_by' => $userId,
            'status' => $status,
        ]);

        $todo->load('completions');

        if ($status === Todo::STATUS_PENDING) {
            $this->notifyPartner(
                $pod,
                $userId,
                'todo_proposed',
                [
                    'pod_id' => $pod->id,
                    'todo_id' => $todo->id,
                    'title' => $todo->title,
                ],
            );
        }

        return $this->success($this->formatTodo($todo, $request->user()), null, 201);
    }

    /**
     * PATCH /api/v1/pods/{pod}/todos/{todo}
     */
    public function update(UpdateTodoRequest $request, Pod $pod, Todo $todo): JsonResponse
    {
        Gate::authorize('view', $pod);
        Gate::authorize('update', $todo);

        if ($todo->status !== Todo::STATUS_ACTIVE) {
            return $this->error(
                'Only active todos can be updated.',
                'todo_not_active',
                null,
                422
            );
        }

        $data = $request->validated();

        if (array_key_exists('my_completed', $data)) {
            $this->setMyCompletion($todo, $request->user()->id, (bool) $data['my_completed']);
            unset($data['my_completed']);
        }

        if ($data !== []) {
            $todo->update($data);
        }

        $todo->load('completions');

        return $this->success($this->formatTodo($todo->fresh('completions'), $request->user()));
    }

    /**
     * DELETE /api/v1/pods/{pod}/todos/{todo}
     *
     * Cancels a pending proposal, requests deletion for active todos, or
     * cancels a pending deletion request.
     */
    public function destroy(Request $request, Pod $pod, Todo $todo): JsonResponse
    {
        Gate::authorize('view', $pod);
        Gate::authorize('delete', $todo);

        $userId = $request->user()->id;

        if ($todo->status === Todo::STATUS_PENDING) {
            if ($todo->created_by !== $userId) {
                return $this->error(
                    'Only the proposer can cancel this todo request.',
                    'forbidden',
                    null,
                    403
                );
            }

            $todo->delete();

            return $this->success(['message' => 'Todo request cancelled.']);
        }

        if ($todo->status === Todo::STATUS_PENDING_DELETION) {
            if ($todo->deletion_requested_by !== $userId) {
                return $this->error(
                    'Only the person who requested deletion can cancel it.',
                    'forbidden',
                    null,
                    403
                );
            }

            $todo->update([
                'status' => Todo::STATUS_ACTIVE,
                'deletion_requested_by' => null,
            ]);

            $todo->load('completions');

            return $this->success($this->formatTodo($todo, $request->user()));
        }

        if ($todo->isPersonalFor($userId)) {
            $todo->delete();

            return $this->success(['message' => 'Todo deleted.']);
        }

        $todo->update([
            'status' => Todo::STATUS_PENDING_DELETION,
            'deletion_requested_by' => $userId,
        ]);

        $todo->load('completions');
        $this->notifyPartner(
            $pod,
            $userId,
            'todo_deletion_requested',
            [
                'pod_id' => $pod->id,
                'todo_id' => $todo->id,
                'title' => $todo->title,
            ],
        );

        return $this->success($this->formatTodo($todo, $request->user()));
    }

    /**
     * POST /api/v1/pods/{pod}/todos/{todo}/approve
     */
    public function approve(Request $request, Pod $pod, Todo $todo): JsonResponse
    {
        Gate::authorize('view', $pod);
        Gate::authorize('approve', $todo);

        $userId = $request->user()->id;

        if ($todo->status === Todo::STATUS_PENDING) {
            if ($todo->created_by === $userId) {
                return $this->error(
                    'You cannot approve your own todo proposal.',
                    'forbidden',
                    null,
                    403
                );
            }

            $todo->update(['status' => Todo::STATUS_ACTIVE]);
            $todo->load('completions');

            return $this->success($this->formatTodo($todo, $request->user()));
        }

        if ($todo->status === Todo::STATUS_PENDING_DELETION) {
            if ($todo->deletion_requested_by === $userId) {
                return $this->error(
                    'You cannot approve your own deletion request.',
                    'forbidden',
                    null,
                    403
                );
            }

            $todo->delete();

            return $this->success(['message' => 'Todo deleted.']);
        }

        return $this->error(
            'This todo is not waiting for approval.',
            'todo_not_pending',
            null,
            422
        );
    }

    /**
     * POST /api/v1/pods/{pod}/todos/{todo}/reject
     */
    public function reject(Request $request, Pod $pod, Todo $todo): JsonResponse
    {
        Gate::authorize('view', $pod);
        Gate::authorize('approve', $todo);

        $userId = $request->user()->id;

        if ($todo->status === Todo::STATUS_PENDING) {
            if ($todo->created_by === $userId) {
                return $this->error(
                    'You cannot reject your own todo proposal.',
                    'forbidden',
                    null,
                    403
                );
            }

            $todo->delete();

            return $this->success(['message' => 'Todo proposal rejected.']);
        }

        if ($todo->status === Todo::STATUS_PENDING_DELETION) {
            if ($todo->deletion_requested_by === $userId) {
                return $this->error(
                    'You cannot reject your own deletion request.',
                    'forbidden',
                    null,
                    403
                );
            }

            $todo->update([
                'status' => Todo::STATUS_ACTIVE,
                'deletion_requested_by' => null,
            ]);
            $todo->load('completions');

            return $this->success($this->formatTodo($todo, $request->user()));
        }

        return $this->error(
            'This todo is not waiting for approval.',
            'todo_not_pending',
            null,
            422
        );
    }

    private function setMyCompletion(Todo $todo, string $userId, bool $completed): void
    {
        if ($completed) {
            TodoCompletion::query()->updateOrCreate(
                [
                    'todo_id' => $todo->id,
                    'user_id' => $userId,
                ],
                [
                    'completed_at' => now(),
                ],
            );
        } else {
            TodoCompletion::query()
                ->where('todo_id', $todo->id)
                ->where('user_id', $userId)
                ->delete();
        }
    }

    /**
     * @return array<string, mixed>
     */
    private function formatTodo(Todo $todo, \App\Models\User $viewer): array
    {
        $completions = $todo->completions
            ->map(fn (TodoCompletion $completion) => [
                'user_id' => $completion->user_id,
                'completed_at' => $completion->completed_at?->toIso8601String(),
            ])
            ->values()
            ->all();

        return [
            'id' => $todo->id,
            'pod_id' => $todo->pod_id,
            'status' => $todo->status,
            'created_by' => $todo->created_by,
            'deletion_requested_by' => $todo->deletion_requested_by,
            'assigned_to' => $todo->assigned_to,
            'title' => $todo->title,
            'notes' => $todo->notes,
            'due_date' => $todo->due_date?->toIso8601String(),
            'completions' => $completions,
            'my_completed' => $todo->completions->contains(
                fn (TodoCompletion $completion) => $completion->user_id === $viewer->id,
            ),
            'created_at' => $todo->created_at?->toIso8601String(),
            'updated_at' => $todo->updated_at?->toIso8601String(),
        ];
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    private function notifyPartner(Pod $pod, string $senderUserId, string $type, array $payload): void
    {
        $partnerId = $pod->podMembers()
            ->whereNull('left_at')
            ->where('user_id', '!=', $senderUserId)
            ->value('user_id');

        if ($partnerId === null) {
            return;
        }

        $partner = \App\Models\User::query()->find($partnerId);
        if ($partner === null) {
            return;
        }

        app(NotificationService::class)->send($partner, $type, $payload);
    }
}
