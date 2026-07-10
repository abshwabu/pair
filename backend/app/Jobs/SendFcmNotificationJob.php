<?php

namespace App\Jobs;

use App\Models\Notification;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Http;

class SendFcmNotificationJob implements ShouldQueue
{
    use Queueable;

    public function __construct(public string $notificationId) {}

    public function handle(): void
    {
        $notification = Notification::query()
            ->with('user:id,fcm_token')
            ->find($this->notificationId);

        if (! $notification || $notification->sent_at) {
            return;
        }

        $fcmToken = $notification->user?->fcm_token;
        $projectId = config('services.fcm.project_id');
        $accessToken = config('services.fcm.access_token');

        if (! $fcmToken || ! $projectId || ! $accessToken) {
            return;
        }

        $response = Http::withToken($accessToken)
            ->post("https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send", [
                'message' => [
                    'token' => $fcmToken,
                    'data' => array_merge(
                        ['type' => $notification->type],
                        collect($notification->payload)
                            ->map(fn ($value) => is_scalar($value) || $value === null ? (string) $value : json_encode($value))
                            ->all()
                    ),
                ],
            ]);

        if ($response->successful()) {
            $notification->forceFill(['sent_at' => now()])->save();
        }
    }
}
