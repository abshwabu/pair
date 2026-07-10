<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    use ApiResponse;

    /**
     * GET /api/v1/notifications
     */
    public function index(Request $request): JsonResponse
    {
        $paginator = Notification::query()
            ->where('user_id', $request->user()->id)
            ->latest('created_at')
            ->paginate(20);

        return $this->success($paginator->items(), [
            'current_page' => $paginator->currentPage(),
            'last_page' => $paginator->lastPage(),
            'per_page' => $paginator->perPage(),
            'total' => $paginator->total(),
        ]);
    }

    /**
     * PATCH /api/v1/notifications/{id}/read
     */
    public function read(Request $request, Notification $notification): JsonResponse
    {
        if ($notification->user_id !== $request->user()->id) {
            abort(403);
        }

        if (! $notification->read_at) {
            $notification->forceFill(['read_at' => now()])->save();
        }

        return $this->success($notification->fresh());
    }
}
