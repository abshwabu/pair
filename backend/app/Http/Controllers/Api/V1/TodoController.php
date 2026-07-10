<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\CreateTodoRequest;
use App\Http\Requests\UpdateTodoRequest;
use App\Models\Pod;
use App\Models\Todo;
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

        $query = $pod->todos();

        if ($request->has('assigned_to')) {
            $assignedTo = $request->query('assigned_to');

            if ($assignedTo === 'null' || $assignedTo === '') {
                $query->whereNull('assigned_to');
            } else {
                $query->where('assigned_to', $assignedTo);
            }
        }

        if ($request->has('is_done')) {
            $query->where('is_done', filter_var($request->query('is_done'), FILTER_VALIDATE_BOOLEAN));
        }

        $sortDirection = strtolower($request->query('sort_direction', 'asc')) === 'desc' ? 'desc' : 'asc';
        $query->orderBy('due_date', $sortDirection);

        return $this->success($query->get());
    }

    /**
     * POST /api/v1/pods/{pod}/todos
     */
    public function store(CreateTodoRequest $request, Pod $pod): JsonResponse
    {
        Gate::authorize('view', $pod);

        $todo = $pod->todos()->create([
            ...$request->validated(),
            'created_by' => $request->user()->id,
        ]);

        return $this->success($todo->fresh(), null, 201);
    }

    /**
     * PATCH /api/v1/pods/{pod}/todos/{todo}
     */
    public function update(UpdateTodoRequest $request, Pod $pod, Todo $todo): JsonResponse
    {
        Gate::authorize('view', $pod);
        Gate::authorize('update', $todo);

        $data = $request->validated();

        if (array_key_exists('is_done', $data)) {
            $data['completed_at'] = $data['is_done'] ? now() : null;
        }

        $todo->update($data);

        return $this->success($todo->fresh());
    }

    /**
     * DELETE /api/v1/pods/{pod}/todos/{todo}
     */
    public function destroy(Pod $pod, Todo $todo): JsonResponse
    {
        Gate::authorize('view', $pod);
        Gate::authorize('delete', $todo);

        $todo->delete();

        return $this->success(['message' => 'Todo deleted successfully.']);
    }
}
