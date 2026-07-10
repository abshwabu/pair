<?php

namespace Tests\Unit;

use App\Models\Goal;
use App\Models\PodRequest;
use App\Models\User;
use App\Services\MatchingScorer;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MatchingScorerTest extends TestCase
{
    use RefreshDatabase;

    private MatchingScorer $scorer;

    protected function setUp(): void
    {
        parent::setUp();
        $this->scorer = new MatchingScorer;
    }

    public function test_scores_compatible_pair_above_threshold(): void
    {
        [$request, $candidate] = $this->createRequestPair(
            categoryA: 'fitness',
            categoryB: 'fitness',
            timezoneA: 'UTC',
            timezoneB: 'UTC',
            toleranceA: 3,
            toleranceB: 3,
            languageA: 'en',
            languageB: 'en',
            paceA: 'steady',
            paceB: 'steady',
        );

        $score = $this->scorer->score($request, $candidate);

        $this->assertGreaterThanOrEqual(MatchingScorer::MIN_SCORE_THRESHOLD, $score);
        $this->assertTrue($this->scorer->meetsThreshold($score));
    }

    public function test_returns_zero_for_different_language(): void
    {
        [$request, $candidate] = $this->createRequestPair(
            languageA: 'en',
            languageB: 'es',
        );

        $this->assertSame(0, $this->scorer->score($request, $candidate));
    }

    public function test_returns_zero_for_different_goal_category(): void
    {
        [$request, $candidate] = $this->createRequestPair(
            categoryA: 'fitness',
            categoryB: 'read',
        );

        $this->assertSame(0, $this->scorer->score($request, $candidate));
    }

    public function test_returns_zero_when_timezone_exceeds_tolerance(): void
    {
        [$request, $candidate] = $this->createRequestPair(
            timezoneA: 'UTC',
            timezoneB: 'America/New_York',
            toleranceA: 1,
            toleranceB: 1,
        );

        $this->assertSame(0, $this->scorer->score($request, $candidate));
    }

    public function test_returns_zero_for_incompatible_pace(): void
    {
        [$request, $candidate] = $this->createRequestPair(
            paceA: 'relaxed',
            paceB: 'intense',
        );

        $this->assertSame(0, $this->scorer->score($request, $candidate));
    }

    public function test_scores_adjacent_pace_above_threshold(): void
    {
        [$request, $candidate] = $this->createRequestPair(
            paceA: 'relaxed',
            paceB: 'steady',
        );

        $score = $this->scorer->score($request, $candidate);

        $this->assertGreaterThanOrEqual(MatchingScorer::MIN_SCORE_THRESHOLD, $score);
    }

    public function test_returns_zero_for_same_user(): void
    {
        $user = User::create([
            'name' => 'Solo User',
            'email' => 'solo@example.com',
            'password' => bcrypt('password'),
            'timezone' => 'UTC',
            'language' => 'en',
        ]);

        $goal = Goal::create([
            'user_id' => $user->id,
            'category' => 'fitness',
            'title' => 'Goal',
            'target_description' => 'Desc',
            'pace' => 'steady',
        ]);

        $request = PodRequest::create([
            'user_id' => $user->id,
            'goal_id' => $goal->id,
            'status' => 'open',
            'timezone_tolerance_hours' => 3,
            'language' => 'en',
        ]);

        $this->assertSame(0, $this->scorer->score($request, $request));
    }

    /**
     * @return array{0: PodRequest, 1: PodRequest}
     */
    private function createRequestPair(
        string $categoryA = 'fitness',
        string $categoryB = 'fitness',
        string $timezoneA = 'UTC',
        string $timezoneB = 'UTC',
        int $toleranceA = 3,
        int $toleranceB = 3,
        string $languageA = 'en',
        string $languageB = 'en',
        string $paceA = 'steady',
        string $paceB = 'steady',
    ): array {
        $userA = User::create([
            'name' => 'User A',
            'email' => 'usera@example.com',
            'password' => bcrypt('password'),
            'timezone' => $timezoneA,
            'language' => $languageA,
        ]);

        $userB = User::create([
            'name' => 'User B',
            'email' => 'userb@example.com',
            'password' => bcrypt('password'),
            'timezone' => $timezoneB,
            'language' => $languageB,
        ]);

        $goalA = Goal::create([
            'user_id' => $userA->id,
            'category' => $categoryA,
            'title' => 'Goal A',
            'target_description' => 'Desc A',
            'pace' => $paceA,
        ]);

        $goalB = Goal::create([
            'user_id' => $userB->id,
            'category' => $categoryB,
            'title' => 'Goal B',
            'target_description' => 'Desc B',
            'pace' => $paceB,
        ]);

        $request = PodRequest::create([
            'user_id' => $userA->id,
            'goal_id' => $goalA->id,
            'status' => 'open',
            'timezone_tolerance_hours' => $toleranceA,
            'language' => $languageA,
        ]);

        $candidate = PodRequest::create([
            'user_id' => $userB->id,
            'goal_id' => $goalB->id,
            'status' => 'open',
            'timezone_tolerance_hours' => $toleranceB,
            'language' => $languageB,
        ]);

        return [$request, $candidate];
    }
}
