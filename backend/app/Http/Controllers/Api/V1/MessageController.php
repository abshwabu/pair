<?php

namespace App\Http\Controllers\Api\V1;

use App\Events\MessageSent;
use App\Events\UserTyping;
use App\Http\Controllers\Controller;
use App\Http\Requests\CreateMessageRequest;
use App\Http\Requests\UploadChatAttachmentRequest;
use App\Support\UploadStorage;
use App\Models\Message;
use App\Models\Pod;
use App\Models\User;
use App\Services\NotificationService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Gate;

class MessageController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly NotificationService $notificationService) {}

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
        $this->notifyRecipientsAboutMessage($pod, $request->user(), $message);

        return $this->success($this->formatMessage($message), null, 201);
    }

    /**
     * POST /api/v1/pods/{pod}/typing
     */
    public function typing(Request $request, Pod $pod): JsonResponse
    {
        Gate::authorize('view', $pod);

        Cache::put($this->chatPresenceCacheKey($request->user()->id, $pod->id), true, now()->addMinute());

        UserTyping::dispatch($pod->id, $request->user());

        return $this->success(['message' => 'Typing indicator sent.']);
    }

    /**
     * POST /api/v1/pods/{pod}/messages/attachments
     */
    public function uploadAttachment(UploadChatAttachmentRequest $request, Pod $pod): JsonResponse
    {
        Gate::authorize('view', $pod);

        $file = $request->file('attachment');
        $upload = UploadStorage::storePublicUrl($file, "chat-attachments/{$pod->id}");

        return $this->success(['attachment_url' => $upload['url']], null, 201);
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

    private function notifyRecipientsAboutMessage(Pod $pod, User $sender, Message $message): void
    {
        $pod->loadMissing('podMembers.user');
        $senderName = $sender->name;
        $preview = $message->body ?: 'Sent an attachment';

        foreach ($pod->podMembers as $member) {
            if ($member->user_id === $sender->id || $member->left_at !== null) {
                continue;
            }

            if (Cache::has($this->chatPresenceCacheKey($member->user_id, $pod->id))) {
                continue;
            }

            $this->notificationService->send($member->user, 'new_message', [
                'pod_id' => $pod->id,
                'message_id' => $message->id,
                'sender_id' => $sender->id,
                'sender_name' => $senderName,
                'preview' => $preview,
            ]);
        }
    }

    private function chatPresenceCacheKey(string $userId, string $podId): string
    {
        return "chat_presence:{$userId}:{$podId}";
    }
}
