<?php

namespace Tests\Feature;

use App\Models\Goal;
use App\Models\Pod;
use App\Models\PodMember;
use App\Models\Streak;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PodTest extends TestCase
{
    use RefreshDatabase;

    public function test_member_can_list_active_pods(): void
    {
        $user = $this->createUser('member@example.com');
        $otherUser = $this->createUser('other@example.com');

        $memberPod = $this->createPodWithMember($user);
        $this->createPodWithMember($otherUser);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/pods');

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $memberPod->id)
            ->assertJsonPath('data.0.status', 'active');
    }

    public function test_member_can_view_pod_detail(): void
    {
        [$pod, $user1, $user2, $goal1, $goal2] = $this->createActivePodPair();

        Streak::create([
            'pod_id' => $pod->id,
            'current_streak' => 5,
            'best_streak' => 10,
            'last_check_in_date' => '2026-07-09',
        ]);

        $response = $this->actingAs($user1, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}");

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'id' => $pod->id,
                    'goal_category' => 'fitness',
                    'status' => 'active',
                    'capacity' => 2,
                    'streak' => [
                        'current_streak' => 5,
                        'best_streak' => 10,
                        'last_check_in_date' => '2026-07-09',
                    ],
                ],
                'error' => null,
            ])
            ->assertJsonCount(2, 'data.members');

        $members = collect($response->json('data.members'));
        $memberUserIds = $members->pluck('user.id')->all();

        $this->assertContains($user1->id, $memberUserIds);
        $this->assertContains($user2->id, $memberUserIds);
        $this->assertEqualsCanonicalizing(
            [$goal1->id, $goal2->id],
            $members->pluck('goal.id')->all()
        );

        $member = $members->firstWhere('user.id', $user1->id);
        $this->assertSame($user1->name, $member['user']['name']);
        $this->assertArrayHasKey('avatar_url', $member['user']);
    }

    public function test_non_member_cannot_view_pod(): void
    {
        [$pod] = $this->createActivePodPair();
        $outsider = $this->createUser('outsider@example.com');

        $this->actingAs($outsider, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}")
            ->assertStatus(403);
    }

    public function test_member_can_leave_pod_and_dissolve_when_below_capacity(): void
    {
        [$pod, $user1, $user2] = $this->createActivePodPair();

        $response = $this->actingAs($user1, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/leave");

        $response->assertStatus(200)
            ->assertJsonPath('data.pod_id', $pod->id)
            ->assertJsonPath('data.status', 'dissolved');

        $this->assertDatabaseHas('pod_members', [
            'pod_id' => $pod->id,
            'user_id' => $user1->id,
        ]);
        $this->assertNotNull(
            PodMember::query()
                ->where('pod_id', $pod->id)
                ->where('user_id', $user1->id)
                ->value('left_at')
        );
        $this->assertDatabaseHas('pods', [
            'id' => $pod->id,
            'status' => 'dissolved',
        ]);

        $this->actingAs($user1, 'sanctum')
            ->getJson('/api/v1/pods')
            ->assertJsonCount(0, 'data');

        $this->actingAs($user2, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}")
            ->assertStatus(200);
    }

    public function test_non_member_cannot_leave_pod(): void
    {
        [$pod] = $this->createActivePodPair();
        $outsider = $this->createUser('outsider@example.com');

        $this->actingAs($outsider, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/leave")
            ->assertStatus(403);

        $this->assertDatabaseHas('pods', [
            'id' => $pod->id,
            'status' => 'active',
        ]);
    }

    /**
     * @return array{0: Pod, 1: User, 2: User, 3: Goal, 4: Goal}
     */
    private function createActivePodPair(): array
    {
        $user1 = $this->createUser('user1@example.com', 'Alice');
        $user2 = $this->createUser('user2@example.com', 'Bob');

        $goal1 = $this->createGoal($user1, 'Alice Goal');
        $goal2 = $this->createGoal($user2, 'Bob Goal');

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

        return [$pod, $user1, $user2, $goal1, $goal2];
    }

    private function createPodWithMember(User $user): Pod
    {
        $goal = $this->createGoal($user);

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

        return $pod;
    }

    private function createUser(string $email, string $name = 'Test User'): User
    {
        return User::create([
            'name' => $name,
            'email' => $email,
            'password' => bcrypt('password'),
            'timezone' => 'UTC',
            'language' => 'en',
        ]);
    }

    private function createGoal(User $user, string $title = 'Test Goal'): Goal
    {
        return Goal::create([
            'user_id' => $user->id,
            'category' => 'fitness',
            'title' => $title,
            'target_description' => 'Description',
            'pace' => 'steady',
        ]);
    }
}
