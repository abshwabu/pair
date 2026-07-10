<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test successful user registration.
     */
    public function test_successful_registration(): void
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password123',
            'timezone' => 'America/New_York',
        ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'data' => [
                    'user' => [
                        'id',
                        'name',
                        'email',
                        'timezone',
                        'created_at',
                        'updated_at',
                    ],
                    'token',
                ],
                'meta',
                'error',
            ]);

        $this->assertDatabaseHas('users', [
            'email' => 'john@example.com',
            'name' => 'John Doe',
            'timezone' => 'America/New_York',
        ]);
    }

    /**
     * Test registration rejects duplicate email.
     */
    public function test_duplicate_email_registration_rejected(): void
    {
        User::create([
            'name' => 'Existing User',
            'email' => 'john@example.com',
            'password' => bcrypt('password123'),
            'timezone' => 'UTC',
        ]);

        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password123',
            'timezone' => 'America/New_York',
        ]);

        $response->assertStatus(422)
            ->assertJson([
                'data' => null,
                'meta' => null,
                'error' => [
                    'message' => 'The email has already been taken.',
                    'code' => 'validation_error',
                ],
            ]);
    }

    /**
     * Test successful login.
     */
    public function test_successful_login(): void
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => bcrypt('password123'),
            'timezone' => 'America/New_York',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'john@example.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    'user' => [
                        'id',
                        'name',
                        'email',
                        'timezone',
                    ],
                    'token',
                ],
                'meta',
                'error',
            ]);
    }

    /**
     * Test wrong password login rejected.
     */
    public function test_wrong_password_rejected(): void
    {
        User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => bcrypt('password123'),
            'timezone' => 'America/New_York',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'john@example.com',
            'password' => 'wrongpassword',
        ]);

        $response->assertStatus(401)
            ->assertJson([
                'data' => null,
                'meta' => null,
                'error' => [
                    'message' => 'Invalid credentials.',
                    'code' => 'invalid_credentials',
                ],
            ]);
    }

    /**
     * Test /me returns correct authenticated user.
     */
    public function test_me_returns_authenticated_user(): void
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => bcrypt('password123'),
            'timezone' => 'America/New_York',
        ]);

        $token = $user->createToken('test_token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/v1/auth/me');

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'id' => $user->id,
                    'name' => 'John Doe',
                    'email' => 'john@example.com',
                ],
                'meta' => null,
                'error' => null,
            ]);
    }

    /**
     * Test logout revokes token.
     */
    public function test_logout_revokes_token(): void
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => bcrypt('password123'),
            'timezone' => 'America/New_York',
        ]);

        $token = $user->createToken('test_token')->plainTextToken;

        $this->assertEquals(1, $user->tokens()->count());

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/v1/auth/logout');

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'message' => 'Logged out successfully.',
                ],
                'meta' => null,
                'error' => null,
            ]);

        $this->assertEquals(0, $user->tokens()->count());
    }
}
