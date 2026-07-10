<?php

namespace App\Services;

use App\Models\Pod;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class AccountDeletionService
{
    public function __construct(private readonly PodMembershipService $podMembershipService) {}

    public function delete(User $user): void
    {
        DB::transaction(function () use ($user) {
            $activePods = Pod::query()
                ->where('status', 'active')
                ->whereHas('podMembers', fn ($query) => $query
                    ->where('user_id', $user->id)
                    ->whereNull('left_at'))
                ->get();

            foreach ($activePods as $pod) {
                foreach ($pod->podMembers()->whereNull('left_at')->get() as $member) {
                    $this->podMembershipService->leave($pod, $member->user);
                }
                $pod->update(['status' => 'dissolved']);
            }

            $user->tokens()->delete();

            $user->update([
                'name' => 'Deleted User',
                'email' => 'deleted_'.$user->id.'@pair.invalid',
                'password' => bcrypt(Str::random(64)),
                'avatar_url' => null,
                'fcm_token' => null,
                'remember_token' => null,
            ]);
        });
    }
}
