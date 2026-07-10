<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Report extends Model
{
    use HasFactory, HasUuids;

    public $timestamps = false;

    protected $fillable = [
        'reporter_id',
        'reported_user_id',
        'pod_id',
        'reason',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'status' => 'string',
            'created_at' => 'datetime',
        ];
    }

    // ─── Relationships ───────────────────────────────────────

    public function reporter(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reporter_id');
    }

    public function reportedUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reported_user_id');
    }

    public function pod(): BelongsTo
    {
        return $this->belongsTo(Pod::class);
    }
}
