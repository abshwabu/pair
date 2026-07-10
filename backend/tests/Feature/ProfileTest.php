<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ProfileTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test getting the authenticated user's profile.
     */
    public function test_get_profile_returns_authenticated_user(): void
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => bcrypt('password123'),
            'timezone' => 'America/New_York',
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/profile');

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'id' => $user->id,
                    'name' => 'John Doe',
                    'email' => 'john@example.com',
                    'timezone' => 'America/New_York',
                ],
                'meta' => null,
                'error' => null,
            ]);
    }

    /**
     * Test updating the user's profile.
     */
    public function test_update_profile_saves_and_persists_data(): void
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => bcrypt('password123'),
            'timezone' => 'America/New_York',
            'language' => 'en',
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->patchJson('/api/v1/profile', [
                'name' => 'John Updated',
                'timezone' => 'Europe/London',
                'language' => 'fr',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'id' => $user->id,
                    'name' => 'John Updated',
                    'timezone' => 'Europe/London',
                    'language' => 'fr',
                ],
                'meta' => null,
                'error' => null,
            ]);

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'name' => 'John Updated',
            'timezone' => 'Europe/London',
            'language' => 'fr',
        ]);
    }

    public function test_update_fcm_token_saves_user_token(): void
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => bcrypt('password123'),
            'timezone' => 'America/New_York',
        ]);

        $this->actingAs($user, 'sanctum')
            ->patchJson('/api/v1/profile/fcm-token', [
                'fcm_token' => 'token_123',
            ])
            ->assertStatus(200)
            ->assertJsonPath('data.fcm_token', 'token_123');

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'fcm_token' => 'token_123',
        ]);
    }

    /**
     * Test successful avatar upload stores to s3.
     */
    public function test_successful_avatar_upload(): void
    {
        Storage::fake('s3');

        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => bcrypt('password123'),
            'timezone' => 'America/New_York',
        ]);

        $file = UploadedFile::fake()->create('avatar.jpg', 100, 'image/jpeg');

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/profile/avatar', [
                'avatar' => $file,
            ]);

        $response->assertStatus(200);

        // Fetch refreshed user
        $user->refresh();

        $this->assertNotNull($user->avatar_url);
        $this->assertStringContainsString('avatars/' . $user->id, $user->avatar_url);

        // Verify storage file exists (parse path from url)
        $path = parse_url($user->avatar_url, PHP_URL_PATH);
        $path = ltrim($path, '/');
        // Strip out 'storage/' if it was prepended by local mock URL driver
        $path = preg_replace('/^storage\//', '', $path);
        
        Storage::disk('s3')->assertExists($path);
    }

    /**
     * Test invalid avatar file type rejected.
     */
    public function test_invalid_avatar_file_type_rejected(): void
    {
        Storage::fake('s3');

        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => bcrypt('password123'),
            'timezone' => 'America/New_York',
        ]);

        $file = UploadedFile::fake()->create('document.pdf', 100); // 100 KB PDF

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/profile/avatar', [
                'avatar' => $file,
            ]);

        $response->assertStatus(422)
            ->assertJson([
                'data' => null,
                'meta' => null,
                'error' => [
                    'message' => 'The avatar field must be an image.',
                    'code' => 'validation_error',
                ],
            ]);
    }

    /**
     * Test oversized avatar file rejected.
     */
    public function test_oversized_avatar_file_rejected(): void
    {
        Storage::fake('s3');

        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => bcrypt('password123'),
            'timezone' => 'America/New_York',
        ]);

        // 6000 KB (approx 6MB, exceeds 5MB / 5120KB limit)
        $file = UploadedFile::fake()->create('large_avatar.jpg', 6000, 'image/jpeg');

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/profile/avatar', [
                'avatar' => $file,
            ]);

        $response->assertStatus(422)
            ->assertJson([
                'data' => null,
                'meta' => null,
                'error' => [
                    'message' => 'The avatar field must not be greater than 5120 kilobytes.',
                    'code' => 'validation_error',
                ],
            ]);
    }
}
