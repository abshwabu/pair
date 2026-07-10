<?php

namespace App\Policies;

use App\Models\Block;
use App\Models\Report;
use App\Models\User;

class ReportPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->is_admin;
    }

    public function update(User $user, Report $report): bool
    {
        return $user->is_admin;
    }
}
