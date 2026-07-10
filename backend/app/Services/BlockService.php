<?php

namespace App\Services;

use App\Models\Block;
use App\Models\Pod;
use App\Models\User;

class BlockService
{
    public function usersAreBlocked(string $userIdA, string $userIdB): bool
    {
        if ($userIdA === $userIdB) {
            return false;
        }

        return Block::query()
            ->where(function ($query) use ($userIdA, $userIdB) {
                $query->where('user_id', $userIdA)
                    ->where('blocked_user_id', $userIdB);
            })
            ->orWhere(function ($query) use ($userIdA, $userIdB) {
                $query->where('user_id', $userIdB)
                    ->where('blocked_user_id', $userIdA);
            })
            ->exists();
    }
}
