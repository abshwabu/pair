<?php

namespace App\Policies;

use App\Models\PodRequest;
use App\Models\User;

class PodRequestPolicy
{
    public function view(User $user, PodRequest $podRequest): bool
    {
        return $user->id === $podRequest->user_id;
    }

    public function cancel(User $user, PodRequest $podRequest): bool
    {
        return $user->id === $podRequest->user_id;
    }
}
