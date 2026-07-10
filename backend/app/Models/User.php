<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, HasUuids, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'avatar_url',
        'timezone',
        'language',
        'fcm_token',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    // ─── Relationships ───────────────────────────────────────

    public function goals(): HasMany
    {
        return $this->hasMany(Goal::class);
    }

    public function podRequests(): HasMany
    {
        return $this->hasMany(PodRequest::class);
    }

    public function podMembers(): HasMany
    {
        return $this->hasMany(PodMember::class);
    }

    /**
     * Pods this user belongs to (via pod_members pivot).
     */
    public function pods(): \Illuminate\Database\Eloquent\Relations\BelongsToMany
    {
        return $this->belongsToMany(Pod::class, 'pod_members')
            ->withPivot('goal_id', 'joined_at', 'left_at');
    }

    public function createdTodos(): HasMany
    {
        return $this->hasMany(Todo::class, 'created_by');
    }

    public function assignedTodos(): HasMany
    {
        return $this->hasMany(Todo::class, 'assigned_to');
    }

    public function messages(): HasMany
    {
        return $this->hasMany(Message::class, 'sender_id');
    }

    public function checkIns(): HasMany
    {
        return $this->hasMany(CheckIn::class);
    }

    public function reportsFiled(): HasMany
    {
        return $this->hasMany(Report::class, 'reporter_id');
    }

    public function reportsReceived(): HasMany
    {
        return $this->hasMany(Report::class, 'reported_user_id');
    }

    public function blocks(): HasMany
    {
        return $this->hasMany(Block::class);
    }

    public function blockedBy(): HasMany
    {
        return $this->hasMany(Block::class, 'blocked_user_id');
    }

    public function notifications(): HasMany
    {
        return $this->hasMany(Notification::class);
    }
}
