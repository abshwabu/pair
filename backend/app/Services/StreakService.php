<?php

namespace App\Services;

use App\Models\CheckIn;
use App\Models\Pod;
use App\Models\Streak;
use Carbon\CarbonInterface;
use Illuminate\Support\Carbon;

class StreakService
{
    public function __construct(private readonly NotificationService $notificationService) {}

    public function todayUtc(): CarbonInterface
    {
        return Carbon::today('UTC');
    }

    public function recalculateAfterCheckIn(Pod $pod, ?CarbonInterface $checkInDate = null): Streak
    {
        $checkInDate ??= $this->todayUtc();

        $streak = $this->getOrCreateStreak($pod);

        if (! $this->bothActiveMembersCheckedInOn($pod, $checkInDate)) {
            return $streak;
        }

        if ($streak->last_check_in_date?->isSameDay($checkInDate)) {
            return $streak;
        }

        $yesterday = $checkInDate->copy()->subDay();

        if ($streak->last_check_in_date?->isSameDay($yesterday)) {
            $streak->current_streak += 1;
        } else {
            $streak->current_streak = 1;
        }

        $streak->last_check_in_date = $checkInDate->toDateString();

        if ($streak->current_streak > $streak->best_streak) {
            $streak->best_streak = $streak->current_streak;
        }

        $streak->save();

        return $streak->fresh();
    }

    public function bothActiveMembersCheckedInOn(Pod $pod, CarbonInterface $date): bool
    {
        $activeMemberIds = $pod->podMembers()
            ->whereNull('left_at')
            ->pluck('user_id');

        if ($activeMemberIds->count() < 2) {
            return false;
        }

        $checkedInCount = CheckIn::query()
            ->where('pod_id', $pod->id)
            ->whereDate('check_in_date', $date->toDateString())
            ->whereIn('user_id', $activeMemberIds)
            ->distinct()
            ->count('user_id');

        return $checkedInCount >= $activeMemberIds->count();
    }

    public function resetMissedStreaks(?CarbonInterface $today = null): int
    {
        $today ??= $this->todayUtc();
        $yesterday = $today->copy()->subDay()->toDateString();
        $brokenStreaks = Streak::query()
            ->with('pod.podMembers.user')
            ->where('current_streak', '>', 0)
            ->whereNotNull('last_check_in_date')
            ->where('last_check_in_date', '<', $yesterday)
            ->get();

        foreach ($brokenStreaks as $streak) {
            foreach ($streak->pod?->podMembers ?? [] as $member) {
                if ($member->left_at !== null || ! $member->user) {
                    continue;
                }

                $this->notificationService->send($member->user, 'streak_broken', [
                    'pod_id' => $streak->pod_id,
                    'last_check_in_date' => $streak->last_check_in_date?->toDateString(),
                ]);
            }
        }

        return Streak::query()
            ->whereIn('id', $brokenStreaks->pluck('id'))
            ->update(['current_streak' => 0]);
    }

    public function getOrCreateStreak(Pod $pod): Streak
    {
        return Streak::firstOrCreate(
            ['pod_id' => $pod->id],
            [
                'current_streak' => 0,
                'best_streak' => 0,
            ]
        );
    }

    public function userCheckedInOn(Pod $pod, string $userId, ?CarbonInterface $date = null): bool
    {
        $date ??= $this->todayUtc();

        return CheckIn::query()
            ->where('pod_id', $pod->id)
            ->where('user_id', $userId)
            ->whereDate('check_in_date', $date->toDateString())
            ->exists();
    }

    /**
     * @return array<string, mixed>
     */
    public function streakSummary(Pod $pod, ?string $userId = null): array
    {
        $streak = $this->getOrCreateStreak($pod);
        $today = $this->todayUtc();

        return [
            'current_streak' => $streak->current_streak,
            'best_streak' => $streak->best_streak,
            'last_check_in_date' => $streak->last_check_in_date?->toDateString(),
            'both_checked_in_today' => $this->bothActiveMembersCheckedInOn($pod, $today),
            'checked_in_today' => $userId !== null
                ? $this->userCheckedInOn($pod, $userId, $today)
                : false,
        ];
    }
}
