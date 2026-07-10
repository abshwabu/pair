<?php

namespace App\Services;

use App\Models\PodRequest;
use DateTime;
use DateTimeZone;

class MatchingScorer
{
    public const MIN_SCORE_THRESHOLD = 70;

    private const SCORE_CATEGORY = 30;

    private const SCORE_TIMEZONE = 25;

    private const SCORE_LANGUAGE = 25;

    private const SCORE_PACE = 20;

    /**
     * Score a candidate pair. Returns 0 when incompatible.
     */
    public function score(PodRequest $request, PodRequest $candidate): int
    {
        if ($request->id === $candidate->id || $request->user_id === $candidate->user_id) {
            return 0;
        }

        if ($request->status !== 'open' || $candidate->status !== 'open') {
            return 0;
        }

        $request->loadMissing(['goal', 'user']);
        $candidate->loadMissing(['goal', 'user']);

        $score = 0;

        if ($request->goal->category !== $candidate->goal->category) {
            return 0;
        }
        $score += self::SCORE_CATEGORY;

        if (! $this->timezonesAreCompatible($request, $candidate)) {
            return 0;
        }
        $score += self::SCORE_TIMEZONE;

        if ($request->language !== $candidate->language) {
            return 0;
        }
        $score += self::SCORE_LANGUAGE;

        $paceScore = $this->paceScore($request->goal->pace, $candidate->goal->pace);
        if ($paceScore === 0) {
            return 0;
        }
        $score += $paceScore;

        return $score;
    }

    public function meetsThreshold(int $score): bool
    {
        return $score >= self::MIN_SCORE_THRESHOLD;
    }

    private function timezonesAreCompatible(PodRequest $request, PodRequest $candidate): bool
    {
        $offsetA = $this->timezoneOffsetHours($request->user->timezone);
        $offsetB = $this->timezoneOffsetHours($candidate->user->timezone);
        $difference = abs($offsetA - $offsetB);

        return $difference <= $request->timezone_tolerance_hours
            && $difference <= $candidate->timezone_tolerance_hours;
    }

    private function timezoneOffsetHours(string $timezone): float
    {
        $tz = new DateTimeZone($timezone);
        $now = new DateTime('now', $tz);

        return $tz->getOffset($now) / 3600;
    }

    private function paceScore(string $paceA, string $paceB): int
    {
        $levels = ['relaxed' => 0, 'steady' => 1, 'intense' => 2];

        $diff = abs($levels[$paceA] - $levels[$paceB]);

        return match ($diff) {
            0 => self::SCORE_PACE,
            1 => (int) (self::SCORE_PACE * 0.5),
            default => 0,
        };
    }
}
