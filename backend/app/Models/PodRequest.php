<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PodRequest extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'user_id',
        'goal_id',
        'status',
        'timezone_tolerance_hours',
        'language',
    ];

    protected function casts(): array
    {
        return [
            'status' => 'string',
            'timezone_tolerance_hours' => 'integer',
        ];
    }

    // ─── Relationships ───────────────────────────────────────

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function goal(): BelongsTo
    {
        return $this->belongsTo(Goal::class);
    }
}
