<?php

namespace App\Support;

use App\Models\Todo;
use Carbon\CarbonInterface;
use Illuminate\Support\Carbon;

final class TodoRecurrence
{
    public const DAILY = 'daily';

    public const WEEKLY = 'weekly';

    public const MONTHLY = 'monthly';

    public const YEARLY = 'yearly';

    /**
     * @return list<string>
     */
    public static function values(): array
    {
        return [
            self::DAILY,
            self::WEEKLY,
            self::MONTHLY,
            self::YEARLY,
        ];
    }

    public static function nextDueDate(CarbonInterface $current, string $recurrence): CarbonInterface
    {
        $date = Carbon::parse($current)->startOfDay();

        return match ($recurrence) {
            self::DAILY => $date->addDay(),
            self::WEEKLY => $date->addWeek(),
            self::MONTHLY => $date->addMonthNoOverflow(),
            self::YEARLY => $date->addYearNoOverflow(),
            default => $date->addDay(),
        };
    }

    /**
     * Move overdue recurring todos to the current period and reset check-offs.
     */
    public static function advanceOverdue(Todo $todo, ?CarbonInterface $today = null): bool
    {
        if ($todo->recurrence === null || $todo->due_date === null) {
            return false;
        }

        if ($todo->status !== Todo::STATUS_ACTIVE) {
            return false;
        }

        $today = Carbon::parse($today ?? now())->startOfDay();
        $due = Carbon::parse($todo->due_date)->startOfDay();

        if ($due->gte($today)) {
            return false;
        }

        while ($due->lt($today)) {
            $due = Carbon::parse(self::nextDueDate($due, $todo->recurrence))->startOfDay();
        }

        $todo->completions()->delete();
        $todo->update(['due_date' => $due]);

        return true;
    }
}
