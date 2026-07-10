<?php

namespace Tests\Feature;

use App\Models\Goal;
use App\Models\PartnerMatchRequest;
use App\Models\Pod;
use App\Models\PodMember;
use App\Models\PodRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PartnerMatchRequestTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_send_partner_match_request(): void
    {
        $requester = $this->createUser('requester@example.com');
        $recipient = $this->createUser('recipient@example.com');

        $requesterGoal = $this->createGoal($requester);
        $recipientGoal = $this->createGoal($recipient);

        PodRequest::create([
            'user_id' => $recipient->id,
            'goal_id' => $recipientGoal->id,
            'status' => 'open',
            'timezone_tolerance_hours' => 3,
            'language' => 'en',
        ]);

        $response = $this->actingAs($requester, 'sanctum')
            ->postJson('/api/v1/matching/partner-requests', [
                'goal_id' => $requesterGoal->id,
                'target_goal_id' => $recipientGoal->id,
                'timezone_tolerance_hours' => 3,
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath('data.recipient_goal.id', $recipientGoal->id);

        $this->assertDatabaseHas('partner_match_requests', [
            'requester_user_id' => $requester->id,
            'recipient_user_id' => $recipient->id,
            'status' => 'pending',
        ]);
    }

    public function test_recipient_can_accept_partner_match_request(): void
    {
        $requester = $this->createUser('requester@example.com');
        $recipient = $this->createUser('recipient@example.com');

        $requesterGoal = $this->createGoal($requester);
        $recipientGoal = $this->createGoal($recipient);

        PodRequest::create([
            'user_id' => $recipient->id,
            'goal_id' => $recipientGoal->id,
            'status' => 'open',
            'timezone_tolerance_hours' => 3,
            'language' => 'en',
        ]);

        $partnerRequest = PartnerMatchRequest::create([
            'requester_user_id' => $requester->id,
            'requester_goal_id' => $requesterGoal->id,
            'recipient_user_id' => $recipient->id,
            'recipient_goal_id' => $recipientGoal->id,
            'status' => 'pending',
            'timezone_tolerance_hours' => 3,
        ]);

        $response = $this->actingAs($recipient, 'sanctum')
            ->postJson("/api/v1/matching/partner-requests/{$partnerRequest->id}/accept");

        $response->assertStatus(200)
            ->assertJsonPath('data.status', 'accepted')
            ->assertJsonStructure(['data' => ['pod_id']]);

        $this->assertDatabaseCount('pods', 1);
        $this->assertDatabaseHas('partner_match_requests', [
            'id' => $partnerRequest->id,
            'status' => 'accepted',
        ]);
    }

    public function test_recipient_can_decline_partner_match_request(): void
    {
        $requester = $this->createUser('requester@example.com');
        $recipient = $this->createUser('recipient@example.com');

        $requesterGoal = $this->createGoal($requester);
        $recipientGoal = $this->createGoal($recipient);

        $partnerRequest = PartnerMatchRequest::create([
            'requester_user_id' => $requester->id,
            'requester_goal_id' => $requesterGoal->id,
            'recipient_user_id' => $recipient->id,
            'recipient_goal_id' => $recipientGoal->id,
            'status' => 'pending',
            'timezone_tolerance_hours' => 3,
        ]);

        $response = $this->actingAs($recipient, 'sanctum')
            ->postJson("/api/v1/matching/partner-requests/{$partnerRequest->id}/decline");

        $response->assertStatus(200)
            ->assertJsonPath('data.status', 'declined');
    }

    public function test_requester_can_cancel_pending_partner_match_request(): void
    {
        $requester = $this->createUser('requester@example.com');
        $recipient = $this->createUser('recipient@example.com');

        $requesterGoal = $this->createGoal($requester);
        $recipientGoal = $this->createGoal($recipient);

        $partnerRequest = PartnerMatchRequest::create([
            'requester_user_id' => $requester->id,
            'requester_goal_id' => $requesterGoal->id,
            'recipient_user_id' => $recipient->id,
            'recipient_goal_id' => $recipientGoal->id,
            'status' => 'pending',
            'timezone_tolerance_hours' => 3,
        ]);

        $response = $this->actingAs($requester, 'sanctum')
            ->deleteJson("/api/v1/matching/partner-requests/{$partnerRequest->id}");

        $response->assertStatus(200)
            ->assertJsonPath('data.status', 'cancelled');
    }

    private function createUser(string $email = 'user@example.com'): User
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
