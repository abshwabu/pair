<?php

namespace App\Services;

use App\Models\Pod;
use App\Models\User;

class PodMembershipService
{
    public function leave(Pod $pod, User $user): void
    {
        $membership = $pod->podMembers()
            ->where('user_id', $user->id)
            ->whereNull('left_at')
            ->first();

        if (! $membership) {
            return;
        }

        $membership->update(['left_at' => now()]);

        if ($pod->podMembers()->whereNull('left_at')->count() < 2) {
            $pod->update(['status' => 'dissolved']);
        }
    }

    public function dissolveSharedActivePods(User $user, User $otherUser): void
    {
        $sharedPods = Pod::query()
            ->where('status', 'active')
            ->whereHas('podMembers', fn ($query) => $query
                ->where('user_id', $user->id)
                ->whereNull('left_at'))
            ->whereHas('podMembers', fn ($query) => $query
                ->where('user_id', $otherUser->id)
                ->whereNull('left_at'))
            ->get();

        foreach ($sharedPods as $pod) {
            $this->leave($pod, $user);
            $this->leave($pod, $otherUser);
            $pod->update(['status' => 'dissolved']);
        }
    }
}
