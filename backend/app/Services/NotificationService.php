<?php

namespace App\Services;

use App\Jobs\SendFcmNotificationJob;
use App\Models\Notification;
use App\Models\User;

class NotificationService
{
    public function send(User $user, string $type, array $payload): Notification
    {
        $notification = Notification::query()->create([
            'user_id' => $user->id,
            'type' => $type,
            'payload' => $payload,
        ]);

        SendFcmNotificationJob::dispatch($notification->id);

        return $notification;
    }
}
