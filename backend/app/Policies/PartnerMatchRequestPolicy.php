<?php

namespace App\Policies;

use App\Models\PartnerMatchRequest;
use App\Models\User;

class PartnerMatchRequestPolicy
{
    public function view(User $user, PartnerMatchRequest $partnerMatchRequest): bool
    {
        return $user->id === $partnerMatchRequest->requester_user_id
            || $user->id === $partnerMatchRequest->recipient_user_id;
    }

    public function cancel(User $user, PartnerMatchRequest $partnerMatchRequest): bool
    {
        return $user->id === $partnerMatchRequest->requester_user_id;
    }

    public function accept(User $user, PartnerMatchRequest $partnerMatchRequest): bool
    {
        return $user->id === $partnerMatchRequest->recipient_user_id;
    }

    public function decline(User $user, PartnerMatchRequest $partnerMatchRequest): bool
    {
        return $user->id === $partnerMatchRequest->recipient_user_id;
    }
}
