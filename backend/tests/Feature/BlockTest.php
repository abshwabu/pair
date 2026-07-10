<?php

namespace Tests\Feature;

use App\Models\Block;
use App\Models\Goal;
use App\Models\Pod;
use App\Models\PodMember;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BlockTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_block_another_user(): void
    {
        $user1 = $this->createUser('user1@example.com');
        $user2 = $this->createUser('user2@example.com');

        $response = $this->actingAs($user1, 'sanctum')
            ->postJson('/api/v1/blocks', [
                'blocked_user_id' => $user2->id,
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.blocked_user.id', $user2->id);

        $this->assertDatabaseHas('blocks', [
            'user_id' => $user1->id,
            'blocked_user_id' => $user2->id,
        ]);
    }

    public function test_blocking_dissolves_shared_active_pod(): void
    {
        [$pod, $user1, $user2] = $this->createActivePodPair();

        $this->actingAs($user1, 'sanctum')
            ->postJson('/api/v1/blocks', [
                'blocked_user_id' => $user2->id,
            ])
            ->assertStatus(201);

        $this->assertDatabaseHas('pods', [
            'id' => $pod->id,
            'status' => 'dissolved',
        ]);

        $this->assertNotNull(
            PodMember::query()
                ->where('pod_id', $pod->id)
                ->where('user_id', $user1->id)
                ->value('left_at')
        );
        $this->assertNotNull(
            PodMember::query()
                ->where('pod_id', $pod->id)
                ->where('user_id', $user2->id)
                ->value('left_at')
        );
    }

    public function test_user_can_list_blocks(): void
    {
        $user1 = $this->createUser('user1@example.com');
        $user2 = $this->createUser('user2@example.com');

        Block::create([
            'user_id' => $user1->id,
            'blocked_user_id' => $user2->id,
        ]);

        $this->actingAs($user1, 'sanctum')
            ->getJson('/api/v1/blocks')
            ->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.blocked_user.id', $user2->id);
    }

    public function test_user_can_unblock(): void
    {
        $user1 = $this->createUser('user1@example.com');
        $user2 = $this->createUser('user2@example.com');

        $block = Block::create([
            'user_id' => $user1->id,
            'blocked_user_id' => $user2->id,
        ]);

        $this->actingAs($user1, 'sanctum')
            ->deleteJson("/api/v1/blocks/{$block->id}")
            ->assertStatus(200);

        $this->assertDatabaseMissing('blocks', ['id' => $block->id]);
    }

    public function test_user_cannot_unblock_another_users_block(): void
    {
        $user1 = $this->createUser('user1@example.com');
        $user2 = $this->createUser('user2@example.com');
        $user3 = $this->createUser('user3@example.com');

        $block = Block::create([
            'user_id' => $user1->id,
            'blocked_user_id' => $user2->id,
        ]);

        $this->actingAs($user3, 'sanctum')
            ->deleteJson("/api/v1/blocks/{$block->id}")
            ->assertStatus(403);

        $this->assertDatabaseHas('blocks', ['id' => $block->id]);
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
