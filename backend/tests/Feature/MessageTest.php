<?php

namespace Tests\Feature;

use App\Events\MessageSent;
use App\Events\UserTyping;
use App\Models\Goal;
use App\Models\Message;
use App\Models\Pod;
use App\Models\PodMember;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Broadcast;
use Illuminate\Support\Facades\Event;
use Tests\TestCase;

class MessageTest extends TestCase
{
    use RefreshDatabase;

    public function test_active_member_can_authorize_pod_channel(): void
    {
        [$pod, $user1] = $this->createActivePodPair();

        $callback = Broadcast::driver()->getChannels()->get('pod.{podId}');

        $this->assertTrue($callback($user1, $pod->id));
    }

    public function test_non_member_cannot_authorize_pod_channel(): void
    {
        [$pod] = $this->createActivePodPair();
        $outsider = $this->createUser('outsider@example.com');

        $callback = Broadcast::driver()->getChannels()->get('pod.{podId}');

        $this->assertFalse($callback($outsider, $pod->id));
    }

    public function test_member_can_send_message_and_it_persists(): void
    {
        Event::fake([MessageSent::class]);

        [$pod, $user1] = $this->createActivePodPair();

        $response = $this->actingAs($user1, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/messages", [
                'body' => 'Hello partner!',
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.body', 'Hello partner!')
            ->assertJsonPath('data.sender.id', $user1->id)
            ->assertJsonPath('error', null);

        $this->assertDatabaseHas('messages', [
            'pod_id' => $pod->id,
            'sender_id' => $user1->id,
            'body' => 'Hello partner!',
        ]);

        Event::assertDispatched(MessageSent::class, function (MessageSent $event) use ($pod, $user1) {
            return $event->message->pod_id === $pod->id
                && $event->message->sender_id === $user1->id
                && $event->message->body === 'Hello partner!'
                && $event->broadcastOn()[0]->name === 'private-pod.'.$pod->id;
        });
    }

    public function test_message_sent_event_broadcasts_expected_payload(): void
    {
        [$pod, $user1] = $this->createActivePodPair();

        $message = Message::create([
            'pod_id' => $pod->id,
            'sender_id' => $user1->id,
            'body' => 'Broadcast me',
            'created_at' => now(),
        ]);

        $message->load('sender:id,name,avatar_url');

        $event = new MessageSent($message);

        $this->assertSame('MessageSent', $event->broadcastAs());
        $this->assertSame([
            'sender' => [
                'id' => $user1->id,
                'name' => $user1->name,
                'avatar_url' => $user1->avatar_url,
            ],
            'body' => 'Broadcast me',
            'attachment_url' => null,
            'created_at' => $message->created_at->toIso8601String(),
        ], $event->broadcastWith());
    }

    public function test_member_can_send_message_with_attachment_only(): void
    {
        Event::fake([MessageSent::class]);

        [$pod, $user1] = $this->createActivePodPair();

        $this->actingAs($user1, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/messages", [
                'attachment_url' => 'https://example.com/photo.jpg',
            ])
            ->assertStatus(201)
            ->assertJsonPath('data.attachment_url', 'https://example.com/photo.jpg')
            ->assertJsonPath('data.body', null);

        Event::assertDispatched(MessageSent::class);
    }

    public function test_message_appears_in_history(): void
    {
        [$pod, $user1, $user2] = $this->createActivePodPair();

        Message::create([
            'pod_id' => $pod->id,
            'sender_id' => $user1->id,
            'body' => 'First message',
            'created_at' => now()->subMinute(),
        ]);

        Message::create([
            'pod_id' => $pod->id,
            'sender_id' => $user2->id,
            'body' => 'Second message',
            'created_at' => now(),
        ]);

        $response = $this->actingAs($user1, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}/messages");

        $response->assertStatus(200)
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.body', 'First message')
            ->assertJsonPath('data.1.body', 'Second message')
            ->assertJsonPath('meta.per_page', 50)
            ->assertJsonPath('meta.has_more', false);
    }

    public function test_message_history_is_cursor_paginated(): void
    {
        [$pod, $user1] = $this->createActivePodPair();

        for ($i = 1; $i <= 51; $i++) {
            Message::create([
                'pod_id' => $pod->id,
                'sender_id' => $user1->id,
                'body' => "Message {$i}",
                'created_at' => now()->subMinutes(60 - $i),
            ]);
        }

        $firstPage = $this->actingAs($user1, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}/messages");

        $firstPage->assertStatus(200)
            ->assertJsonCount(50, 'data')
            ->assertJsonPath('meta.has_more', true)
            ->assertJsonPath('data.0.body', 'Message 2')
            ->assertJsonPath('data.49.body', 'Message 51');

        $nextCursor = $firstPage->json('meta.next_cursor');
        $this->assertNotNull($nextCursor);

        $secondPage = $this->actingAs($user1, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}/messages?cursor={$nextCursor}");

        $secondPage->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.body', 'Message 1')
            ->assertJsonPath('meta.has_more', false);
    }

    public function test_typing_indicator_broadcasts_without_persisting(): void
    {
        Event::fake([UserTyping::class]);

        [$pod, $user1] = $this->createActivePodPair();

        $this->actingAs($user1, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/typing")
            ->assertStatus(200);

        $this->assertDatabaseCount('messages', 0);

        Event::assertDispatched(UserTyping::class, function (UserTyping $event) use ($pod, $user1) {
            return $event->podId === $pod->id
                && $event->user->id === $user1->id
                && $event->broadcastOn()[0]->name === 'private-pod.'.$pod->id;
        });
    }

    public function test_non_member_cannot_access_messages(): void
    {
        [$pod, $user1] = $this->createActivePodPair();
        $outsider = $this->createUser('outsider@example.com');

        $this->actingAs($outsider, 'sanctum')
            ->getJson("/api/v1/pods/{$pod->id}/messages")
            ->assertStatus(403);

        $this->actingAs($outsider, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/messages", ['body' => 'Hack'])
            ->assertStatus(403);

        $this->actingAs($outsider, 'sanctum')
            ->postJson("/api/v1/pods/{$pod->id}/typing")
            ->assertStatus(403);
    }

    /**
     * @return array{0: Pod, 1: User, 2: User}
     */
    private function createActivePodPair(): array
    {
        $user1 = $this->createUser('user1@example.com');
        $user2 = $this->createUser('user2@example.com');

        $goal1 = $this->createGoal($user1);
        $goal2 = $this->createGoal($user2);

        $pod = Pod::create([
            'goal_category' => 'fitness',
            'status' => 'active',
            'capacity' => 2,
        ]);

        PodMember::create([
            'pod_id' => $pod->id,
            'user_id' => $user1->id,
            'goal_id' => $goal1->id,
            'joined_at' => now(),
        ]);

        PodMember::create([
            'pod_id' => $pod->id,
            'user_id' => $user2->id,
            'goal_id' => $goal2->id,
            'joined_at' => now(),
        ]);

        return [$pod, $user1, $user2];
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

    private function createGoal(User $user): Goal
    {
        return Goal::create([
            'user_id' => $user->id,
            'category' => 'fitness',
            'title' => 'Test Goal',
            'target_description' => 'Description',
            'pace' => 'steady',
        ]);
    }
}
