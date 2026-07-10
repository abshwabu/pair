<?php

namespace Tests\Feature;

use App\Models\Goal;
use App\Models\Pod;
use App\Models\PodMember;
use App\Models\Todo;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TodoTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_create_shared_todo(): void
    {
        [$pod, $user1] = $this->createActivePodPair();

        $response = $this->actingAs($user1, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/todos", [
                'title' => 'Morning run',
                'notes' => 'Before breakfast',
                'due_date' => '2026-07-15',
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.pod_id', $pod->id)
            ->assertJsonPath('data.created_by', $user1->id)
            ->assertJsonPath('data.assigned_to', null)
            ->assertJsonPath('data.title', 'Morning run')
            ->assertJsonPath('data.notes', 'Before breakfast')
            ->assertJsonPath('data.due_date', '2026-07-15T00:00:00.000000Z')
            ->assertJsonPath('data.is_done', false)
            ->assertJsonPath('error', null);

        $this->assertDatabaseHas('todos', [
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'assigned_to' => null,
            'title' => 'Morning run',
        ]);
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
            ->assertJsonPath('data.assigned_to', $user2->id);
    }

    public function test_member_can_list_todos_sorted_by_due_date(): void
    {
        [$pod, $user1] = $this->createActivePodPair();

        Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'title' => 'Later',
            'due_date' => '2026-07-20',
        ]);

        Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'title' => 'Sooner',
            'due_date' => '2026-07-10',
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
        ]);

        Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'assigned_to' => null,
            'title' => 'Shared task',
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

    public function test_member_can_filter_todos_by_is_done(): void
    {
        [$pod, $user1] = $this->createActivePodPair();

        Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'title' => 'Done task',
            'is_done' => true,
            'completed_at' => now(),
        ]);

        Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'title' => 'Open task',
            'is_done' => false,
        ]);

        $this->actingAs($user1, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}/todos?is_done=1")
            ->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title', 'Done task');

        $this->actingAs($user1, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}/todos?is_done=0")
            ->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title', 'Open task');
    }

    public function test_member_can_update_todo(): void
    {
        [$pod, $user1] = $this->createActivePodPair();

        $todo = Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'title' => 'Old title',
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

    public function test_marking_todo_done_sets_completed_at(): void
    {
        [$pod, $user1] = $this->createActivePodPair();

        $todo = Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'title' => 'Task',
            'is_done' => false,
        ]);

        $response = $this->actingAs($user1, 'sanctum')
            ->patchJson("/api/v1/pods/{$pod->id}/todos/{$todo->id}", [
                'is_done' => true,
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.is_done', true);

        $this->assertNotNull($response->json('data.completed_at'));
        $this->assertNotNull(Todo::find($todo->id)->completed_at);
    }

    public function test_marking_todo_undone_clears_completed_at(): void
    {
        [$pod, $user1] = $this->createActivePodPair();

        $todo = Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'title' => 'Task',
            'is_done' => true,
            'completed_at' => now(),
        ]);

        $response = $this->actingAs($user1, 'sanctum')
            ->patchJson("/api/v1/pods/{$pod->id}/todos/{$todo->id}", [
                'is_done' => false,
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.is_done', false)
            ->assertJsonPath('data.completed_at', null);

        $this->assertNull(Todo::find($todo->id)->completed_at);
    }

    public function test_creator_can_delete_assigned_todo(): void
    {
        [$pod, $user1, $user2] = $this->createActivePodPair();

        $todo = Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'assigned_to' => $user2->id,
            'title' => 'Assigned task',
        ]);

        $this->actingAs($user1, 'sanctum')
            ->deleteJson("/api/v1/pods/{$pod->id}/todos/{$todo->id}")
            ->assertStatus(200);

        $this->assertDatabaseMissing('todos', ['id' => $todo->id]);
    }

    public function test_member_can_delete_unassigned_todo_they_did_not_create(): void
    {
        [$pod, $user1, $user2] = $this->createActivePodPair();

        $todo = Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'assigned_to' => null,
            'title' => 'Shared task',
        ]);

        $this->actingAs($user2, 'sanctum')
            ->deleteJson("/api/v1/pods/{$pod->id}/todos/{$todo->id}")
            ->assertStatus(200);

        $this->assertDatabaseMissing('todos', ['id' => $todo->id]);
    }

    public function test_non_creator_cannot_delete_assigned_todo(): void
    {
        [$pod, $user1, $user2] = $this->createActivePodPair();

        $todo = Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'assigned_to' => $user2->id,
            'title' => 'Assigned task',
        ]);

        $this->actingAs($user2, 'sanctum')
            ->deleteJson("/api/v1/pods/{$pod->id}/todos/{$todo->id}")
            ->assertStatus(403);

        $this->assertDatabaseHas('todos', ['id' => $todo->id]);
    }

    public function test_non_member_cannot_access_todos(): void
    {
        [$pod, $user1] = $this->createActivePodPair();
        $outsider = $this->createUser('outsider@example.com');

        $todo = Todo::create([
            'pod_id' => $pod->id,
            'created_by' => $user1->id,
            'title' => 'Task',
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
