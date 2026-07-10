<?php

namespace Tests\Feature;

use App\Models\Goal;
use App\Models\Pod;
use App\Models\PodMember;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class GoalTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test successful goal creation.
     */
    public function test_user_can_create_goal(): void
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => bcrypt('password123'),
            'timezone' => 'UTC',
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/goals', [
                'category' => 'fitness',
                'title' => 'Lose 5kg',
                'target_description' => 'Work out 3 times a week',
                'pace' => 'steady',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'data' => [
                    'category' => 'fitness',
                    'title' => 'Lose 5kg',
                    'target_description' => 'Work out 3 times a week',
                    'pace' => 'steady',
                    'user_id' => $user->id,
                ],
                'meta' => null,
                'error' => null,
            ]);

        $this->assertDatabaseHas('goals', [
            'user_id' => $user->id,
            'title' => 'Lose 5kg',
        ]);
    }

    /**
     * Test listing authenticated user's goals.
     */
    public function test_user_can_list_own_goals(): void
    {
        $user1 = User::create([
            'name' => 'User 1',
            'email' => 'user1@example.com',
            'password' => bcrypt('password123'),
            'timezone' => 'UTC',
        ]);

        $user2 = User::create([
            'name' => 'User 2',
            'email' => 'user2@example.com',
            'password' => bcrypt('password123'),
            'timezone' => 'UTC',
        ]);

        $goal1 = Goal::create([
            'user_id' => $user1->id,
            'category' => 'fitness',
            'title' => 'User 1 Goal',
            'target_description' => 'Desc 1',
            'pace' => 'steady',
        ]);

        Goal::create([
            'user_id' => $user2->id,
            'category' => 'read',
            'title' => 'User 2 Goal',
            'target_description' => 'Desc 2',
            'pace' => 'relaxed',
        ]);

        $response = $this->actingAs($user1, 'sanctum')
            ->getJson('/api/v1/goals');

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $goal1->id);
    }

    /**
     * Test showing a single owned goal.
     */
    public function test_user_can_show_own_goal(): void
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => bcrypt('password123'),
            'timezone' => 'UTC',
        ]);

        $goal = Goal::create([
            'user_id' => $user->id,
            'category' => 'fitness',
            'title' => 'Lose 5kg',
            'target_description' => 'Desc',
            'pace' => 'steady',
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson("/api/v1/goals/{$goal->id}");

        $response->assertStatus(200)
            ->assertJsonPath('data.id', $goal->id);
    }

    /**
     * Test other users' goal access is forbidden.
     */
    public function test_user_cannot_access_other_users_goal(): void
    {
        $user1 = User::create([
            'name' => 'User 1',
            'email' => 'user1@example.com',
            'password' => bcrypt('password123'),
            'timezone' => 'UTC',
        ]);

        $user2 = User::create([
            'name' => 'User 2',
            'email' => 'user2@example.com',
            'password' => bcrypt('password123'),
            'timezone' => 'UTC',
        ]);

        $goal = Goal::create([
            'user_id' => $user2->id,
            'category' => 'fitness',
            'title' => 'User 2 Goal',
            'target_description' => 'Desc',
            'pace' => 'steady',
        ]);

        // GET other's goal
        $response = $this->actingAs($user1, 'sanctum')
            ->getJson("/api/v1/goals/{$goal->id}");
        $response->assertStatus(403);

        // PATCH other's goal
        $response = $this->actingAs($user1, 'sanctum')
            ->patchJson("/api/v1/goals/{$goal->id}", ['title' => 'Hack']);
        $response->assertStatus(403);

        // DELETE other's goal
        $response = $this->actingAs($user1, 'sanctum')
            ->deleteJson("/api/v1/goals/{$goal->id}");
        $response->assertStatus(403);
    }

    /**
     * Test successful goal update and deletion.
     */
    public function test_user_can_update_and_delete_goal(): void
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => bcrypt('password123'),
            'timezone' => 'UTC',
        ]);

        $goal = Goal::create([
            'user_id' => $user->id,
            'category' => 'fitness',
            'title' => 'Old Title',
            'target_description' => 'Desc',
            'pace' => 'steady',
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->patchJson("/api/v1/goals/{$goal->id}", [
                'title' => 'New Title',
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.title', 'New Title');

        $response = $this->actingAs($user, 'sanctum')
            ->deleteJson("/api/v1/goals/{$goal->id}");

        $response->assertStatus(200);
        $this->assertDatabaseMissing('goals', ['id' => $goal->id]);
    }

    /**
     * Test update and delete are blocked when goal is attached to an active pod.
     */
    public function test_cannot_update_or_delete_goal_attached_to_active_pod(): void
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => bcrypt('password123'),
            'timezone' => 'UTC',
        ]);

        $goal = Goal::create([
            'user_id' => $user->id,
            'category' => 'fitness',
            'title' => 'Attached Goal',
            'target_description' => 'Desc',
            'pace' => 'steady',
        ]);

        $pod = Pod::create([
            'goal_category' => 'fitness',
            'status' => 'active',
            'capacity' => 2,
        ]);

        PodMember::create([
            'pod_id' => $pod->id,
            'user_id' => $user->id,
            'goal_id' => $goal->id,
            'joined_at' => now(),
        ]);

        // Attempt update
        $response = $this->actingAs($user, 'sanctum')
            ->patchJson("/api/v1/goals/{$goal->id}", [
                'title' => 'Attempt Update',
            ]);

        $response->assertStatus(422)
            ->assertJson([
                'data' => null,
                'meta' => null,
                'error' => [
                    'message' => 'Cannot update a goal that is already attached to an active pod.',
                    'code' => 'goal_attached_to_active_pod',
                ],
            ]);

        // Attempt delete
        $response = $this->actingAs($user, 'sanctum')
            ->deleteJson("/api/v1/goals/{$goal->id}");

        $response->assertStatus(422)
            ->assertJson([
                'data' => null,
                'meta' => null,
                'error' => [
                    'message' => 'Cannot delete a goal that is already attached to an active pod.',
                    'code' => 'goal_attached_to_active_pod',
                ],
            ]);
    }
}
