<?php

namespace App\Policies;

use App\Models\Pod;
use App\Models\User;

class PodPolicy
{
    public function view(User $user, Pod $pod): bool
    {
        return $this->isActiveMember($user, $pod);
    }

    public function leave(User $user, Pod $pod): bool
    {
        return $this->isActiveMember($user, $pod);
    }

    private function isActiveMember(User $user, Pod $pod): bool
    {
        return $pod->podMembers()
            ->where('user_id', $user->id)
            ->whereNull('left_at')
            ->exists();
    }
}
