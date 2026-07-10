<?php

namespace Tests\Feature;

use App\Jobs\SendFcmNotificationJob;
use App\Models\CheckIn;
use App\Models\Goal;
use App\Models\Pod;
use App\Models\PodMember;
use App\Models\Streak;
use App\Models\User;
use App\Services\StreakService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class CheckInTest extends TestCase
{
    use RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }

    public function test_single_check_in_does_not_increment_streak(): void
    {
        Queue::fake();
        Carbon::setTestNow('2026-07-10 12:00:00');

        [$pod, $user1] = $this->createActivePodPair();

        $this->actingAs($user1, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/check-ins", [
                'note' => 'Done for today',
            ])
            ->assertStatus(201)
            ->assertJsonPath('data.note', 'Done for today');

        $this->actingAs($user1, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}/streak")
            ->assertStatus(200)
            ->assertJson([
                'data' => [
                    'current_streak' => 0,
                    'best_streak' => 0,
                    'last_check_in_date' => null,
                    'both_checked_in_today' => false,
                    'checked_in_today' => true,
                ],
            ]);

        Queue::assertPushed(SendFcmNotificationJob::class);
    }

    public function test_both_members_checking_in_same_day_increments_streak(): void
    {
        Carbon::setTestNow('2026-07-10 12:00:00');

        [$pod, $user1, $user2] = $this->createActivePodPair();

        $this->actingAs($user1, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/check-ins")
            ->assertStatus(201);

        $this->actingAs($user2, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/check-ins")
            ->assertStatus(201);

        $this->actingAs($user1, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}/streak")
            ->assertStatus(200)
            ->assertJson([
                'data' => [
                    'current_streak' => 1,
                    'best_streak' => 1,
                    'last_check_in_date' => '2026-07-10',
                    'both_checked_in_today' => true,
                ],
            ]);
    }

    public function test_consecutive_days_increment_streak(): void
    {
        Carbon::setTestNow('2026-07-10 12:00:00');

        [$pod, $user1, $user2] = $this->createActivePodPair();

        $this->checkInBothMembers($pod, $user1, $user2);

        Carbon::setTestNow('2026-07-11 12:00:00');

        $this->checkInBothMembers($pod, $user1, $user2);

        $this->actingAs($user1, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}/streak")
            ->assertJsonPath('data.current_streak', 2)
            ->assertJsonPath('data.best_streak', 2)
            ->assertJsonPath('data.last_check_in_date', '2026-07-11');
    }

    public function test_missed_day_resets_streak(): void
    {
        Queue::fake();
        Carbon::setTestNow('2026-07-10 12:00:00');

        [$pod, $user1, $user2] = $this->createActivePodPair();

        $this->checkInBothMembers($pod, $user1, $user2);

        Carbon::setTestNow('2026-07-12 00:05:00');

        $this->artisan('streaks:reset-missed')->assertSuccessful();
        Queue::assertPushed(SendFcmNotificationJob::class);

        $this->actingAs($user1, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}/streak")
            ->assertJsonPath('data.current_streak', 0)
            ->assertJsonPath('data.best_streak', 1)
            ->assertJsonPath('data.last_check_in_date', '2026-07-10');

        $this->checkInBothMembers($pod, $user1, $user2);

        $this->actingAs($user1, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}/streak")
            ->assertJsonPath('data.current_streak', 1)
            ->assertJsonPath('data.best_streak', 1)
            ->assertJsonPath('data.last_check_in_date', '2026-07-12');
    }

    public function test_duplicate_check_in_same_day_returns_409(): void
    {
        Carbon::setTestNow('2026-07-10 12:00:00');

        [$pod, $user1] = $this->createActivePodPair();

        $this->actingAs($user1, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/check-ins")
            ->assertStatus(201);

        $this->actingAs($user1, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/check-ins")
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'check_in_already_exists');

        $this->assertDatabaseCount('check_ins', 1);
    }

    public function test_member_can_list_check_ins_most_recent_first(): void
    {
        Carbon::setTestNow('2026-07-10 12:00:00');

        [$pod, $user1, $user2] = $this->createActivePodPair();

        CheckIn::create([
            'pod_id' => $pod->id,
            'user_id' => $user1->id,
            'check_in_date' => '2026-07-09',
            'note' => 'Older',
        ]);

        CheckIn::create([
            'pod_id' => $pod->id,
            'user_id' => $user2->id,
            'check_in_date' => '2026-07-10',
            'note' => 'Newer',
        ]);

        $this->actingAs($user1, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}/check-ins")
            ->assertStatus(200)
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.note', 'Newer')
            ->assertJsonPath('data.1.note', 'Older');
    }

    public function test_streak_reports_checked_in_today_for_current_user(): void
    {
        Carbon::setTestNow('2026-07-10 12:00:00');

        [$pod, $user1, $user2] = $this->createActivePodPair();

        $this->actingAs($user1, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}/streak")
            ->assertJsonPath('data.checked_in_today', false);

        $this->actingAs($user1, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/check-ins")
            ->assertStatus(201)
            ->assertJsonPath('meta.streak.checked_in_today', true)
            ->assertJsonPath('meta.streak.current_streak', 0);

        $this->actingAs($user2, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}/streak")
            ->assertJsonPath('data.checked_in_today', false);

        $this->actingAs($user2, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/check-ins")
            ->assertStatus(201)
            ->assertJsonPath('meta.streak.both_checked_in_today', true)
            ->assertJsonPath('meta.streak.current_streak', 1);
    }

    public function test_member_can_nudge_partner(): void
    {
        Queue::fake();
        Carbon::setTestNow('2026-07-10 12:00:00');

        [$pod, $user1] = $this->createActivePodPair();

        $this->actingAs($user1, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/nudge")
            ->assertStatus(200)
            ->assertJsonPath('data.sent', true);

        Queue::assertPushed(SendFcmNotificationJob::class);
    }

    public function test_non_member_cannot_access_check_ins(): void
    {
        [$pod] = $this->createActivePodPair();
        $outsider = $this->createUser('outsider@example.com');

        $this->actingAs($outsider, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/check-ins")
            ->assertStatus(403);

        $this->actingAs($outsider, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}/check-ins")
            ->assertStatus(403);

        $this->actingAs($outsider, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}/streak")
            ->assertStatus(403);
    }

    public function test_streak_service_resets_streaks_older_than_yesterday(): void
    {
        Carbon::setTestNow('2026-07-12 00:00:00');

        [$pod] = $this->createActivePodPair();

        Streak::create([
            'pod_id' => $pod->id,
            'current_streak' => 4,
            'best_streak' => 7,
            'last_check_in_date' => '2026-07-10',
        ]);

        $resetCount = app(StreakService::class)->resetMissedStreaks();

        $this->assertSame(1, $resetCount);
        $this->assertDatabaseHas('streaks', [
            'pod_id' => $pod->id,
            'current_streak' => 0,
            'best_streak' => 7,
        ]);
    }

    private function checkInBothMembers(Pod $pod, User $user1, User $user2): void
    {
        $this->actingAs($user1, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/check-ins")
            ->assertStatus(201);

        $this->actingAs($user2, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/check-ins")
            ->assertStatus(201);
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
