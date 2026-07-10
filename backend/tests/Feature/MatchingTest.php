<?php

namespace Tests\Feature;

use App\Jobs\FindMatchJob;
use App\Jobs\SendFcmNotificationJob;
use App\Models\Block;
use App\Models\Goal;
use App\Models\Pod;
use App\Models\PodMember;
use App\Models\PodRequest;
use App\Models\User;
use App\Services\BlockService;
use App\Services\MatchingScorer;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class MatchingTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_create_matching_request(): void
    {
        $user = $this->createUser();
        $goal = $this->createGoal($user);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/matching/request', [
                'goal_id' => $goal->id,
                'timezone_tolerance_hours' => 3,
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'data' => [
                    'status' => 'open',
                ],
                'meta' => null,
                'error' => null,
            ])
            ->assertJsonStructure(['data' => ['id', 'status']]);

        $this->assertDatabaseHas('pod_requests', [
            'user_id' => $user->id,
            'goal_id' => $goal->id,
            'status' => 'open',
            'timezone_tolerance_hours' => 3,
            'language' => 'en',
        ]);
    }

    public function test_compatible_users_get_paired_within_one_job_run(): void
    {
        Queue::fake();
        $user1 = $this->createUser('user1@example.com', 'UTC', 'en');
        $user2 = $this->createUser('user2@example.com', 'UTC', 'en');

        $goal1 = $this->createGoal($user1, 'fitness', 'steady');
        $goal2 = $this->createGoal($user2, 'fitness', 'steady');

        $request1 = PodRequest::create([
            'user_id' => $user1->id,
            'goal_id' => $goal1->id,
            'status' => 'open',
            'timezone_tolerance_hours' => 3,
            'language' => 'en',
        ]);

        $this->runFindMatchJob($request1->id);

        $this->assertDatabaseHas('pod_requests', [
            'id' => $request1->id,
            'status' => 'open',
        ]);

        $request2 = PodRequest::create([
            'user_id' => $user2->id,
            'goal_id' => $goal2->id,
            'status' => 'open',
            'timezone_tolerance_hours' => 3,
            'language' => 'en',
        ]);

        $this->runFindMatchJob($request2->id);

        $this->assertDatabaseHas('pod_requests', [
            'id' => $request1->id,
            'status' => 'matched',
        ]);
        $this->assertDatabaseHas('pod_requests', [
            'id' => $request2->id,
            'status' => 'matched',
        ]);

        $pod = Pod::query()->where('status', 'active')->first();
        $this->assertNotNull($pod);
        $this->assertSame('fitness', $pod->goal_category);
        $this->assertSame(2, $pod->capacity);

        $this->assertDatabaseCount('pod_members', 2);
        $this->assertDatabaseHas('pod_members', [
            'pod_id' => $pod->id,
            'user_id' => $user1->id,
            'goal_id' => $goal1->id,
        ]);
        $this->assertDatabaseHas('pod_members', [
            'pod_id' => $pod->id,
            'user_id' => $user2->id,
            'goal_id' => $goal2->id,
        ]);

        Queue::assertPushed(SendFcmNotificationJob::class);
    }

    public function test_incompatible_language_users_do_not_get_paired(): void
    {
        $user1 = $this->createUser('user1@example.com', 'UTC', 'en');
        $user2 = $this->createUser('user2@example.com', 'UTC', 'es');

        $goal1 = $this->createGoal($user1);
        $goal2 = $this->createGoal($user2);

        $request1 = PodRequest::create([
            'user_id' => $user1->id,
            'goal_id' => $goal1->id,
            'status' => 'open',
            'timezone_tolerance_hours' => 3,
            'language' => 'en',
        ]);

        $request2 = PodRequest::create([
            'user_id' => $user2->id,
            'goal_id' => $goal2->id,
            'status' => 'open',
            'timezone_tolerance_hours' => 3,
            'language' => 'es',
        ]);

        $this->runFindMatchJob($request2->id);

        $this->assertDatabaseHas('pod_requests', ['id' => $request1->id, 'status' => 'open']);
        $this->assertDatabaseHas('pod_requests', ['id' => $request2->id, 'status' => 'open']);
        $this->assertDatabaseCount('pods', 0);
        $this->assertDatabaseCount('pod_members', 0);
    }

    public function test_user_can_poll_matching_request_status(): void
    {
        $user = $this->createUser();
        $goal = $this->createGoal($user);

        $podRequest = PodRequest::create([
            'user_id' => $user->id,
            'goal_id' => $goal->id,
            'status' => 'open',
            'timezone_tolerance_hours' => 3,
            'language' => 'en',
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson("/api/v1/matching/request/{$podRequest->id}");

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'id' => $podRequest->id,
                    'status' => 'open',
                    'pod_id' => null,
                ],
                'error' => null,
            ]);
    }

    public function test_matched_request_returns_pod_id(): void
    {
        $user = $this->createUser();
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

        $podRequest = PodRequest::create([
            'user_id' => $user->id,
            'goal_id' => $goal->id,
            'status' => 'matched',
            'timezone_tolerance_hours' => 3,
            'language' => 'en',
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson("/api/v1/matching/request/{$podRequest->id}");

        $response->assertStatus(200)
            ->assertJsonPath('data.status', 'matched')
            ->assertJsonPath('data.pod_id', $pod->id);
    }

    public function test_user_can_cancel_open_matching_request(): void
    {
        $user = $this->createUser();
        $goal = $this->createGoal($user);

        $podRequest = PodRequest::create([
            'user_id' => $user->id,
            'goal_id' => $goal->id,
            'status' => 'open',
            'timezone_tolerance_hours' => 3,
            'language' => 'en',
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->deleteJson("/api/v1/matching/request/{$podRequest->id}");

        $response->assertStatus(200)
            ->assertJsonPath('data.status', 'cancelled');

        $this->assertDatabaseHas('pod_requests', [
            'id' => $podRequest->id,
            'status' => 'cancelled',
        ]);
    }

    public function test_cannot_cancel_non_open_matching_request(): void
    {
        $user = $this->createUser();
        $goal = $this->createGoal($user);

        $podRequest = PodRequest::create([
            'user_id' => $user->id,
            'goal_id' => $goal->id,
            'status' => 'matched',
            'timezone_tolerance_hours' => 3,
            'language' => 'en',
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->deleteJson("/api/v1/matching/request/{$podRequest->id}");

        $response->assertStatus(422)
            ->assertJsonPath('error.code', 'request_not_open');
    }

    public function test_user_cannot_access_other_users_matching_request(): void
    {
        $user1 = $this->createUser('user1@example.com');
        $user2 = $this->createUser('user2@example.com');
        $goal = $this->createGoal($user2);

        $podRequest = PodRequest::create([
            'user_id' => $user2->id,
            'goal_id' => $goal->id,
            'status' => 'open',
            'timezone_tolerance_hours' => 3,
            'language' => 'en',
        ]);

        $this->actingAs($user1, 'sanctum')
            ->getJson("/api/v1/matching/request/{$podRequest->id}")
            ->assertStatus(403);

        $this->actingAs($user1, 'sanctum')
            ->deleteJson("/api/v1/matching/request/{$podRequest->id}")
            ->assertStatus(403);
    }

    public function test_cannot_create_second_open_matching_request(): void
    {
        $user = $this->createUser();
        $goal1 = $this->createGoal($user, 'fitness');
        $goal2 = $this->createGoal($user, 'read', 'steady', 'Second Goal');

        PodRequest::create([
            'user_id' => $user->id,
            'goal_id' => $goal1->id,
            'status' => 'open',
            'timezone_tolerance_hours' => 3,
            'language' => 'en',
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/matching/request', [
                'goal_id' => $goal2->id,
                'timezone_tolerance_hours' => 3,
            ]);

        $response->assertStatus(422)
            ->assertJsonPath('error.code', 'open_request_exists');
    }

    public function test_sweep_command_dispatches_jobs_for_stale_open_requests(): void
    {
        Queue::fake();

        $user = $this->createUser();
        $goal = $this->createGoal($user);

        $staleRequest = PodRequest::create([
            'user_id' => $user->id,
            'goal_id' => $goal->id,
            'status' => 'open',
            'timezone_tolerance_hours' => 3,
            'language' => 'en',
        ]);

        $staleRequest->forceFill([
            'created_at' => now()->subMinutes(3),
            'updated_at' => now()->subMinutes(3),
        ])->save();

        $this->artisan('matching:sweep')->assertSuccessful();

        Queue::assertPushed(FindMatchJob::class, function (FindMatchJob $job) use ($staleRequest) {
            return $job->podRequestId === $staleRequest->id;
        });
    }

    public function test_api_flow_pairs_compatible_users_via_sync_queue(): void
    {
        $user1 = $this->createUser('user1@example.com', 'UTC', 'en');
        $user2 = $this->createUser('user2@example.com', 'UTC', 'en');

        $goal1 = $this->createGoal($user1, 'fitness', 'steady');
        $goal2 = $this->createGoal($user2, 'fitness', 'steady');

        $this->actingAs($user1, 'sanctum')
            ->postJson('/api/v1/matching/request', [
                'goal_id' => $goal1->id,
                'timezone_tolerance_hours' => 3,
            ])
            ->assertStatus(201);

        $response = $this->actingAs($user2, 'sanctum')
            ->postJson('/api/v1/matching/request', [
                'goal_id' => $goal2->id,
                'timezone_tolerance_hours' => 3,
            ]);

        $request2Id = $response->json('data.id');

        $this->assertDatabaseHas('pod_requests', ['status' => 'matched']);
        $this->assertDatabaseCount('pods', 1);
        $this->assertDatabaseCount('pod_members', 2);

        $pollResponse = $this->actingAs($user2, 'sanctum')
            ->getJson("/api/v1/matching/request/{$request2Id}");

        $pollResponse->assertStatus(200)
            ->assertJsonPath('data.status', 'matched');

        $this->assertNotNull($pollResponse->json('data.pod_id'));
    }

    public function test_blocked_users_are_not_matched(): void
    {
        $user1 = $this->createUser('user1@example.com', 'UTC', 'en');
        $user2 = $this->createUser('user2@example.com', 'UTC', 'en');

        $goal1 = $this->createGoal($user1, 'fitness', 'steady');
        $goal2 = $this->createGoal($user2, 'fitness', 'steady');

        Block::create([
            'user_id' => $user1->id,
            'blocked_user_id' => $user2->id,
        ]);

        $request1 = PodRequest::create([
            'user_id' => $user1->id,
            'goal_id' => $goal1->id,
            'status' => 'open',
            'timezone_tolerance_hours' => 3,
            'language' => 'en',
        ]);

        $request2 = PodRequest::create([
            'user_id' => $user2->id,
            'goal_id' => $goal2->id,
            'status' => 'open',
            'timezone_tolerance_hours' => 3,
            'language' => 'en',
        ]);

        $this->runFindMatchJob($request2->id);

        $this->assertDatabaseHas('pod_requests', ['id' => $request1->id, 'status' => 'open']);
        $this->assertDatabaseHas('pod_requests', ['id' => $request2->id, 'status' => 'open']);
        $this->assertDatabaseCount('pods', 0);
    }

    private function runFindMatchJob(string $podRequestId): void
    {
        (new FindMatchJob($podRequestId))->handle(
            app(MatchingScorer::class),
            app(BlockService::class),
            app(\App\Services\NotificationService::class),
        );
    }

    private function createUser(
        string $email = 'user@example.com',
        string $timezone = 'UTC',
        string $language = 'en',
    ): User {
        return User::create([
            'name' => 'Test User',
            'email' => $email,
            'password' => bcrypt('password'),
            'timezone' => $timezone,
            'language' => $language,
        ]);
    }

    private function createGoal(
        User $user,
        string $category = 'fitness',
        string $pace = 'steady',
        string $title = 'Test Goal',
    ): Goal {
        return Goal::create([
            'user_id' => $user->id,
            'category' => $category,
            'title' => $title,
            'target_description' => 'Description',
            'pace' => $pace,
        ]);
    }
}
