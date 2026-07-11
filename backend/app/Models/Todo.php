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
        'status',
        'created_by',
        'deletion_requested_by',
        'assigned_to',
        'title',
        'notes',
        'due_date',
        'is_done',
        'completed_at',
    ];

    public const STATUS_PENDING = 'pending';

    public const STATUS_ACTIVE = 'active';

    public const STATUS_PENDING_DELETION = 'pending_deletion';

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

    public function deletionRequester(): BelongsTo
    {
        return $this->belongsTo(User::class, 'deletion_requested_by');
    }

    public function completions(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(TodoCompletion::class);
    }

    /**
     * Personal "Me" todos are assigned to a single member's list.
     * Shared and partner-assigned todos require both members to agree on changes.
     */
    public function isPersonalFor(?string $userId): bool
    {
        return $userId !== null && $this->assigned_to === $userId;
    }
}
