<?php

namespace Tests\Feature;

use App\Models\Goal;
use App\Models\Pod;
use App\Models\PodMember;
use App\Models\Report;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ReportTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_create_report(): void
    {
        $reporter = $this->createUser('reporter@example.com');
        $reported = $this->createUser('reported@example.com');

        $response = $this->actingAs($reporter, 'sanctum')
            ->postJson('/api/v1/reports', [
                'reported_user_id' => $reported->id,
                'reason' => 'Inappropriate behavior',
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.reason', 'Inappropriate behavior')
            ->assertJsonPath('data.status', 'open')
            ->assertJsonPath('data.reported_user.id', $reported->id);

        $this->assertDatabaseHas('reports', [
            'reporter_id' => $reporter->id,
            'reported_user_id' => $reported->id,
            'status' => 'open',
        ]);
    }

    public function test_admin_can_list_open_reports(): void
    {
        $admin = $this->createUser('admin@example.com', true);
        $reporter = $this->createUser('reporter@example.com');
        $reported = $this->createUser('reported@example.com');

        Report::create([
            'reporter_id' => $reporter->id,
            'reported_user_id' => $reported->id,
            'reason' => 'Open report',
            'status' => 'open',
        ]);

        Report::create([
            'reporter_id' => $reporter->id,
            'reported_user_id' => $reported->id,
            'reason' => 'Reviewed report',
            'status' => 'reviewed',
        ]);

        $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/reports')
            ->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.reason', 'Open report');
    }

    public function test_non_admin_cannot_list_reports(): void
    {
        $user = $this->createUser('user@example.com');

        $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/reports')
            ->assertStatus(403);
    }

    public function test_admin_can_update_report_status(): void
    {
        $admin = $this->createUser('admin@example.com', true);
        $reporter = $this->createUser('reporter@example.com');
        $reported = $this->createUser('reported@example.com');

        $report = Report::create([
            'reporter_id' => $reporter->id,
            'reported_user_id' => $reported->id,
            'reason' => 'Needs review',
            'status' => 'open',
        ]);

        $this->actingAs($admin, 'sanctum')
            ->patchJson("/api/v1/reports/{$report->id}", [
                'status' => 'reviewed',
            ])
            ->assertStatus(200)
            ->assertJsonPath('data.status', 'reviewed');

        $this->assertDatabaseHas('reports', [
            'id' => $report->id,
            'status' => 'reviewed',
        ]);
    }

    public function test_non_admin_cannot_update_report(): void
    {
        $user = $this->createUser('user@example.com');
        $reported = $this->createUser('reported@example.com');

        $report = Report::create([
            'reporter_id' => $user->id,
            'reported_user_id' => $reported->id,
            'reason' => 'Issue',
            'status' => 'open',
        ]);

        $this->actingAs($user, 'sanctum')
            ->patchJson("/api/v1/reports/{$report->id}", [
                'status' => 'dismissed',
            ])
            ->assertStatus(403);
    }

    private function createUser(string $email, bool $isAdmin = false): User
    {
        return User::create([
            'name' => 'Test User',
            'email' => $email,
            'password' => bcrypt('password'),
            'timezone' => 'UTC',
            'language' => 'en',
            'is_admin' => $isAdmin,
        ]);
    }
}
