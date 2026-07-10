<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Todo extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'pod_id',
        'created_by',
        'assigned_to',
        'title',
        'notes',
        'due_date',
        'is_done',
        'completed_at',
    ];

    protected function casts(): array
    {
        return [
            'due_date' => 'date',
            'is_done' => 'boolean',
            'completed_at' => 'datetime',
        ];
    }

    // ─── Relationships ───────────────────────────────────────

    public function pod(): BelongsTo
    {
        return $this->belongsTo(Pod::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function assignee(): BelongsTo
    {
        return $this->belongsTo(User::class, 'assigned_to');
    }
}
