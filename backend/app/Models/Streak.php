<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Streak extends Model
{
    use HasFactory, HasUuids;

    const CREATED_AT = null;

    protected $fillable = [
        'pod_id',
        'current_streak',
        'best_streak',
        'last_check_in_date',
    ];

    protected function casts(): array
    {
        return [
            'current_streak' => 'integer',
            'best_streak' => 'integer',
            'last_check_in_date' => 'date',
        ];
    }

    // ─── Relationships ───────────────────────────────────────

    public function pod(): BelongsTo
    {
        return $this->belongsTo(Pod::class);
    }
}
