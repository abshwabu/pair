<?php

namespace App\Http\Controllers\Api\V1;

use App\Events\MessageSent;
use App\Events\UserTyping;
use App\Http\Controllers\Controller;
use App\Http\Requests\CreateMessageRequest;
use App\Models\Message;
use App\Models\Pod;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class MessageController extends Controller
{
    use ApiResponse;

    /**
     * GET /api/v1/pods/{pod}/messages
     */
    public function index(Request $request, Pod $pod): JsonResponse
    {
        Gate::authorize('view', $pod);

        $paginator = $pod->messages()
            ->with('sender:id,name,avatar_url')
            ->orderByDesc('created_at')
            ->orderByDesc('id')
            ->cursorPaginate(50, ['*'], 'cursor', $request->query('cursor'));

        $messages = collect($paginator->items())
            ->reverse()
            ->values()
            ->map(fn (Message $message) => $this->formatMessage($message));

        return $this->success($messages, [
            'next_cursor' => $paginator->nextCursor()?->encode(),
            'prev_cursor' => $paginator->previousCursor()?->encode(),
            'per_page' => 50,
            'has_more' => $paginator->hasMorePages(),
        ]);
    }

    /**
     * POST /api/v1/pods/{pod}/messages
     */
    public function store(CreateMessageRequest $request, Pod $pod): JsonResponse
    {
        Gate::authorize('view', $pod);

        $message = $pod->messages()->create([
            'sender_id' => $request->user()->id,
            'body' => $request->validated('body'),
            'attachment_url' => $request->validated('attachment_url'),
        ]);

        $message = $message->fresh(['sender:id,name,avatar_url']);

        MessageSent::dispatch($message);

        return $this->success($this->formatMessage($message), null, 201);
    }

    /**
     * POST /api/v1/pods/{pod}/typing
     */
    public function typing(Request $request, Pod $pod): JsonResponse
    {
        Gate::authorize('view', $pod);

        UserTyping::dispatch($pod->id, $request->user());

        return $this->success(['message' => 'Typing indicator sent.']);
    }

    /**
     * @return array<string, mixed>
     */
    private function formatMessage(Message $message): array
    {
        $message->loadMissing('sender:id,name,avatar_url');

        return [
            'id' => $message->id,
            'pod_id' => $message->pod_id,
            'sender' => [
                'id' => $message->sender->id,
                'name' => $message->sender->name,
                'avatar_url' => $message->sender->avatar_url,
            ],
            'body' => $message->body,
            'attachment_url' => $message->attachment_url,
            'created_at' => $message->created_at?->toIso8601String(),
        ];
    }
}
