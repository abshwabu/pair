<?php

namespace Tests\Feature;

use App\Models\Goal;
use App\Models\Pod;
use App\Models\PodMember;
use App\Models\Todo;
use App\Models\TodoCompletion;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TodoTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_propose_shared_todo_pending_until_partner_approves(): void
    {
        [$pod, $user1, $user2] = $this->createActivePodPair();

        $response = $this->actingAs($user1, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/todos", [
                'title' => 'Morning run',
                'notes' => 'Before breakfast',
                'due_date' => '2026-07-15',
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.pod_id', $pod->id)
            ->assertJsonPath('data.created_by', $user1->id)
            ->assertJsonPath('data.status', Todo::STATUS_PENDING)
            ->assertJsonPath('data.title', 'Morning run')
            ->assertJsonPath('data.my_completed', false)
            ->assertJsonPath('error', null);

        $this->assertDatabaseHas('todos', [
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'status' => Todo::STATUS_PENDING,
            'title' => 'Morning run',
        ]);

        $todoId = $response->json('data.id');

        $this->actingAs($user2, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/todos/{$todoId}/approve")
            ->assertStatus(200)
            ->assertJsonPath('data.status', Todo::STATUS_ACTIVE);

        $this->assertDatabaseHas('todos', [
            'id' => $todoId,
            'status' => Todo::STATUS_ACTIVE,
        ]);
    }

    public function test_member_can_create_personal_todo_without_approval(): void
    {
        [$pod, $user1] = $this->createActivePodPair();

        $response = $this->actingAs($user1, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/todos", [
                'title' => 'Personal task',
                'assigned_to' => $user1->id,
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.status', Todo::STATUS_ACTIVE)
            ->assertJsonPath('data.assigned_to', $user1->id);

        $this->assertDatabaseHas('todos', [
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'assigned_to' => $user1->id,
            'status' => Todo::STATUS_ACTIVE,
            'title' => 'Personal task',
        ]);
    }

    public function test_member_can_delete_personal_todo_immediately(): void
    {
        [$pod, $user1] = $this->createActivePodPair();

        $todo = Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'assigned_to' => $user1->id,
            'title' => 'Personal task',
            'status' => Todo::STATUS_ACTIVE,
        ]);

        $this->actingAs($user1, 'sanctum')
            ->deleteJson("/api/v1/pods/{$pod->id}/todos/{$todo->id}")
            ->assertStatus(200);

        $this->assertDatabaseMissing('todos', ['id' => $todo->id]);
    }

    public function test_partner_assigned_todo_requires_approval_on_create(): void
    {
        [$pod, $user1, $user2] = $this->createActivePodPair();

        $this->actingAs($user1, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/todos", [
                'title' => 'For partner',
                'assigned_to' => $user2->id,
            ])
            ->assertStatus(201)
            ->assertJsonPath('data.status', Todo::STATUS_PENDING)
            ->assertJsonPath('data.assigned_to', $user2->id);
    }

    public function test_partner_can_reject_pending_todo_proposal(): void
    {
        [$pod, $user1, $user2] = $this->createActivePodPair();

        $todo = Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'title' => 'Rejected task',
            'status' => Todo::STATUS_PENDING,
        ]);

        $this->actingAs($user2, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/todos/{$todo->id}/reject")
            ->assertStatus(200);

        $this->assertDatabaseMissing('todos', ['id' => $todo->id]);
    }

    public function test_proposer_can_cancel_pending_todo(): void
    {
        [$pod, $user1] = $this->createActivePodPair();

        $todo = Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'title' => 'Cancelled task',
            'status' => Todo::STATUS_PENDING,
        ]);

        $this->actingAs($user1, 'sanctum')
            ->deleteJson("/api/v1/pods/{$pod->id}/todos/{$todo->id}")
            ->assertStatus(200);

        $this->assertDatabaseMissing('todos', ['id' => $todo->id]);
    }

    public function test_member_can_create_assigned_todo(): void
    {
        [$pod, $user1, $user2] = $this->createActivePodPair();

        $response = $this->actingAs($user1, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/todos", [
                'title' => 'Read chapter 3',
                'assigned_to' => $user2->id,
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.assigned_to', $user2->id)
            ->assertJsonPath('data.status', Todo::STATUS_PENDING);
    }

    public function test_member_can_list_todos_sorted_by_due_date(): void
    {
        [$pod, $user1] = $this->createActivePodPair();

        Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'title' => 'Later',
            'due_date' => '2026-07-20',
            'status' => Todo::STATUS_ACTIVE,
        ]);

        Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'title' => 'Sooner',
            'due_date' => '2026-07-10',
            'status' => Todo::STATUS_ACTIVE,
        ]);

        $response = $this->actingAs($user1, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}/todos?sort_direction=asc");

        $response->assertStatus(200)
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.title', 'Sooner')
            ->assertJsonPath('data.1.title', 'Later');
    }

    public function test_member_can_filter_todos_by_assigned_to(): void
    {
        [$pod, $user1, $user2] = $this->createActivePodPair();

        Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'assigned_to' => $user2->id,
            'title' => 'Assigned to Bob',
            'status' => Todo::STATUS_ACTIVE,
        ]);

        Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'assigned_to' => null,
            'title' => 'Shared task',
            'status' => Todo::STATUS_ACTIVE,
        ]);

        $this->actingAs($user1, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}/todos?assigned_to={$user2->id}")
            ->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title', 'Assigned to Bob');

        $this->actingAs($user1, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}/todos?assigned_to=null")
            ->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title', 'Shared task');
    }

    public function test_member_can_filter_todos_by_status(): void
    {
        [$pod, $user1] = $this->createActivePodPair();

        Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'title' => 'Pending task',
            'status' => Todo::STATUS_PENDING,
        ]);

        Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'title' => 'Active task',
            'status' => Todo::STATUS_ACTIVE,
        ]);

        $this->actingAs($user1, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}/todos?status=pending")
            ->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title', 'Pending task');
    }

    public function test_member_can_update_active_todo(): void
    {
        [$pod, $user1] = $this->createActivePodPair();

        $todo = Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'title' => 'Old title',
            'status' => Todo::STATUS_ACTIVE,
        ]);

        $response = $this->actingAs($user1, 'sanctum')
            ->patchJson("/api/v1/pods/{$pod->id}/todos/{$todo->id}", [
                'title' => 'New title',
                'notes' => 'Updated notes',
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.title', 'New title')
            ->assertJsonPath('data.notes', 'Updated notes');
    }

    public function test_cannot_update_non_active_todo_fields(): void
    {
        [$pod, $user1] = $this->createActivePodPair();

        $todo = Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'title' => 'Pending task',
            'status' => Todo::STATUS_PENDING,
        ]);

        $this->actingAs($user1, 'sanctum')
            ->patchJson("/api/v1/pods/{$pod->id}/todos/{$todo->id}", [
                'title' => 'New title',
            ])
            ->assertStatus(422);
    }

    public function test_each_member_toggles_their_own_completion_independently(): void
    {
        [$pod, $user1, $user2] = $this->createActivePodPair();

        $todo = Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'title' => 'Task',
            'status' => Todo::STATUS_ACTIVE,
        ]);

        $this->actingAs($user1, 'sanctum')
            ->patchJson("/api/v1/pods/{$pod->id}/todos/{$todo->id}", [
                'my_completed' => true,
            ])
            ->assertStatus(200)
            ->assertJsonPath('data.my_completed', true);

        $this->assertDatabaseHas('todo_completions', [
            'todo_id' => $todo->id,
            'user_id' => $user1->id,
        ]);

        $this->actingAs($user2, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}/todos")
            ->assertStatus(200)
            ->assertJsonPath('data.0.my_completed', false);

        $this->actingAs($user2, 'sanctum')
            ->patchJson("/api/v1/pods/{$pod->id}/todos/{$todo->id}", [
                'my_completed' => true,
            ])
            ->assertStatus(200)
            ->assertJsonPath('data.my_completed', true);

        $this->assertEquals(2, TodoCompletion::where('todo_id', $todo->id)->count());
    }

    public function test_member_can_uncheck_their_completion(): void
    {
        [$pod, $user1] = $this->createActivePodPair();

        $todo = Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'title' => 'Task',
            'status' => Todo::STATUS_ACTIVE,
        ]);

        TodoCompletion::create([
            'todo_id' => $todo->id,
            'user_id' => $user1->id,
            'completed_at' => now(),
        ]);

        $this->actingAs($user1, 'sanctum')
            ->patchJson("/api/v1/pods/{$pod->id}/todos/{$todo->id}", [
                'my_completed' => false,
            ])
            ->assertStatus(200)
            ->assertJsonPath('data.my_completed', false);

        $this->assertDatabaseMissing('todo_completions', [
            'todo_id' => $todo->id,
            'user_id' => $user1->id,
        ]);
    }

    public function test_delete_on_active_todo_requests_partner_approval(): void
    {
        [$pod, $user1, $user2] = $this->createActivePodPair();

        $todo = Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'title' => 'Shared task',
            'status' => Todo::STATUS_ACTIVE,
        ]);

        $this->actingAs($user1, 'sanctum')
            ->deleteJson("/api/v1/pods/{$pod->id}/todos/{$todo->id}")
            ->assertStatus(200)
            ->assertJsonPath('data.status', Todo::STATUS_PENDING_DELETION)
            ->assertJsonPath('data.deletion_requested_by', $user1->id);

        $this->assertDatabaseHas('todos', [
            'id' => $todo->id,
            'status' => Todo::STATUS_PENDING_DELETION,
        ]);

        $this->actingAs($user2, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/todos/{$todo->id}/approve")
            ->assertStatus(200);

        $this->assertDatabaseMissing('todos', ['id' => $todo->id]);
    }

    public function test_partner_can_reject_deletion_request(): void
    {
        [$pod, $user1, $user2] = $this->createActivePodPair();

        $todo = Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'title' => 'Keep me',
            'status' => Todo::STATUS_PENDING_DELETION,
            'deletion_requested_by' => $user1->id,
        ]);

        $this->actingAs($user2, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/todos/{$todo->id}/reject")
            ->assertStatus(200)
            ->assertJsonPath('data.status', Todo::STATUS_ACTIVE)
            ->assertJsonPath('data.deletion_requested_by', null);

        $this->assertDatabaseHas('todos', [
            'id' => $todo->id,
            'status' => Todo::STATUS_ACTIVE,
        ]);
    }

    public function test_requester_can_cancel_pending_deletion(): void
    {
        [$pod, $user1] = $this->createActivePodPair();

        $todo = Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'title' => 'Task',
            'status' => Todo::STATUS_PENDING_DELETION,
            'deletion_requested_by' => $user1->id,
        ]);

        $this->actingAs($user1, 'sanctum')
            ->deleteJson("/api/v1/pods/{$pod->id}/todos/{$todo->id}")
            ->assertStatus(200)
            ->assertJsonPath('data.status', Todo::STATUS_ACTIVE);

        $this->assertDatabaseHas('todos', [
            'id' => $todo->id,
            'status' => Todo::STATUS_ACTIVE,
            'deletion_requested_by' => null,
        ]);
    }

    public function test_proposer_cannot_approve_own_todo(): void
    {
        [$pod, $user1] = $this->createActivePodPair();

        $todo = Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'title' => 'Task',
            'status' => Todo::STATUS_PENDING,
        ]);

        $this->actingAs($user1, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/todos/{$todo->id}/approve")
            ->assertStatus(403);
    }

    public function test_non_member_cannot_access_todos(): void
    {
        [$pod, $user1] = $this->createActivePodPair();
        $outsider = $this->createUser('outsider@example.com');

        $todo = Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'title' => 'Task',
            'status' => Todo::STATUS_ACTIVE,
        ]);

        $this->actingAs($outsider, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}/todos")
            ->assertStatus(403);

        $this->actingAs($outsider, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/todos", ['title' => 'Hack'])
            ->assertStatus(403);

        $this->actingAs($outsider, 'sanctum')
            ->patchJson("/api/v1/pods/{$pod->id}/todos/{$todo->id}", ['title' => 'Hack'])
            ->assertStatus(403);

        $this->actingAs($outsider, 'sanctum')
            ->deleteJson("/api/v1/pods/{$pod->id}/todos/{$todo->id}")
            ->assertStatus(403);
    }

    /**
     * @return array{0: Pod, 1: User, 2: User}
     */
    private function createActivePodPair(): array
    {
        $user1 = $this->createUser('user1@example.com');
        $user2 = $this->createUser('user2@example.com');

        $goal1 = $this->createGoal($user1);
        $goal2 = $this->createGoal($user2);

        $pod = Pod::create([
            'goal_category' => 'fitness',
            'status' => 'active',
            'capacity' => 2,
        ]);

        PodMember::create([
            'pod_id' => $pod->id,
            'user_id' => $user1->id,
            'goal_id' => $goal1->id,
            'joined_at' => now(),
        ]);

        PodMember::create([
            'pod_id' => $pod->id,
            'user_id' => $user2->id,
            'goal_id' => $goal2->id,
            'joined_at' => now(),
        ]);

        return [$pod, $user1, $user2];
    }

    private function createUser(string $email): User
    {
        return User::create([
            'name' => 'Test User',
            'email' => $email,
            'password' => bcrypt('password'),
            'timezone' => 'UTC',
            'language' => 'en',
        ]);
    }

    private function createGoal(User $user): Goal
    {
        return Goal::create([
            'user_id' => $user->id,
            'category' => 'fitness',
            'title' => 'Test Goal',
            'target_description' => 'Description',
            'pace' => 'steady',
        ]);
    }
}
