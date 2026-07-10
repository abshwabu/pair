<?php

namespace Tests\Feature;

use App\Models\Notification;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NotificationTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_list_own_notifications(): void
    {
        $user = $this->createUser('user@example.com');
        $otherUser = $this->createUser('other@example.com');

        Notification::create([
            'user_id' => $user->id,
            'type' => 'new_message',
            'payload' => ['pod_id' => 'pod-1'],
            'created_at' => now(),
        ]);

        Notification::create([
            'user_id' => $otherUser->id,
            'type' => 'new_message',
            'payload' => ['pod_id' => 'pod-2'],
            'created_at' => now(),
        ]);

        $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/notifications')
            ->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.user_id', $user->id)
            ->assertJsonPath('meta.per_page', 20);
    }

    public function test_user_can_mark_notification_as_read(): void
    {
        $user = $this->createUser('user@example.com');

        $notification = Notification::create([
            'user_id' => $user->id,
            'type' => 'match_found',
            'payload' => ['pod_id' => 'pod-1'],
            'created_at' => now(),
        ]);

        $this->actingAs($user, 'sanctum')
            ->patchJson("/api/v1/notifications/{$notification->id}/read")
            ->assertStatus(200)
            ->assertJsonPath('data.id', $notification->id);

        $this->assertDatabaseHas('notifications', [
            'id' => $notification->id,
            'user_id' => $user->id,
        ]);

        $this->assertNotNull($notification->fresh()->read_at);
    }

    public function test_user_cannot_mark_other_user_notification_as_read(): void
    {
        $user = $this->createUser('user@example.com');
        $otherUser = $this->createUser('other@example.com');

        $notification = Notification::create([
            'user_id' => $otherUser->id,
            'type' => 'match_found',
            'payload' => ['pod_id' => 'pod-1'],
            'created_at' => now(),
        ]);

        $this->actingAs($user, 'sanctum')
            ->patchJson("/api/v1/notifications/{$notification->id}/read")
            ->assertStatus(403);
    }

    private function createUser(string $email): User
    {
        return User::create([
            'name' => 'Test User',
            'email' => $email,
            'password' => bcrypt('password'),
            'timezone' => 'UTC',
            'language' => 'en',
        ]);
    }
}
