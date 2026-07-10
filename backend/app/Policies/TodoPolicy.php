<?php

namespace App\Policies;

use App\Models\Pod;
use App\Models\Todo;
use App\Models\User;

class TodoPolicy
{
    public function update(User $user, Todo $todo): bool
    {
        return $this->isActivePodMember($user, $todo->pod);
    }

    public function delete(User $user, Todo $todo): bool
    {
        if (! $this->isActivePodMember($user, $todo->pod)) {
            return false;
        }

        return $todo->created_by === $user->id || $todo->assigned_to === null;
    }

    private function isActivePodMember(User $user, Pod $pod): bool
    {
        return $pod->podMembers()
            ->where('user_id', $user->id)
            ->whereNull('left_at')
            ->exists();
    }
}
