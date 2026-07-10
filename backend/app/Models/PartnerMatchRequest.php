<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PartnerMatchRequest extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'requester_user_id',
        'requester_goal_id',
        'recipient_user_id',
        'recipient_goal_id',
        'status',
        'timezone_tolerance_hours',
        'pod_id',
    ];

    protected function casts(): array
    {
        return [
            'status' => 'string',
            'timezone_tolerance_hours' => 'integer',
        ];
    }

    public function requester(): BelongsTo
    {
        return $this->belongsTo(User::class, 'requester_user_id');
    }

    public function recipient(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recipient_user_id');
    }

    public function requesterGoal(): BelongsTo
    {
        return $this->belongsTo(Goal::class, 'requester_goal_id');
    }

    public function recipientGoal(): BelongsTo
    {
        return $this->belongsTo(Goal::class, 'recipient_goal_id');
    }

    public function pod(): BelongsTo
    {
        return $this->belongsTo(Pod::class);
    }
}
