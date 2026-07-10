<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Goal extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'user_id',
        'category',
        'title',
        'target_description',
        'pace',
    ];

    protected function casts(): array
    {
        return [
            'category' => 'string',
            'pace' => 'string',
        ];
    }

    // ─── Relationships ───────────────────────────────────────

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function podRequests(): HasMany
    {
        return $this->hasMany(PodRequest::class);
    }

    public function podMembers(): HasMany
    {
        return $this->hasMany(PodMember::class);
    }
}
