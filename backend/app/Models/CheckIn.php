<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CheckIn extends Model
{
    use HasFactory, HasUuids;

    public $timestamps = false;

    protected $fillable = [
        'pod_id',
        'user_id',
        'check_in_date',
        'note',
    ];

    protected function casts(): array
    {
        return [
            'check_in_date' => 'date',
            'created_at' => 'datetime',
        ];
    }

    // ─── Relationships ───────────────────────────────────────

    public function pod(): BelongsTo
    {
        return $this->belongsTo(Pod::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
