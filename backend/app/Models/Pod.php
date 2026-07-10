<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Pod extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'goal_category',
        'status',
        'capacity',
    ];

    protected function casts(): array
    {
        return [
            'status' => 'string',
            'capacity' => 'integer',
        ];
    }

    // ─── Relationships ───────────────────────────────────────

    /**
     * Users in this pod (via pod_members pivot).
     */
    public function members(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'pod_members')
            ->withPivot('goal_id', 'joined_at', 'left_at');
    }

    public function podMembers(): HasMany
    {
        return $this->hasMany(PodMember::class);
    }

    public function todos(): HasMany
    {
        return $this->hasMany(Todo::class);
    }

    public function messages(): HasMany
    {
        return $this->hasMany(Message::class);
    }

    public function checkIns(): HasMany
    {
        return $this->hasMany(CheckIn::class);
    }

    public function streak(): HasOne
    {
        return $this->hasOne(Streak::class);
    }

    public function reports(): HasMany
    {
        return $this->hasMany(Report::class);
    }
}
