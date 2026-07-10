<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\CreateBlockRequest;
use App\Models\Block;
use App\Models\User;
use App\Services\PodMembershipService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class BlockController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly PodMembershipService $podMembershipService) {}

    /**
     * POST /api/v1/blocks
     */
    public function store(CreateBlockRequest $request): JsonResponse
    {
        $blockedUser = User::findOrFail($request->validated('blocked_user_id'));

        $existingBlock = Block::query()
            ->where('user_id', $request->user()->id)
            ->where('blocked_user_id', $blockedUser->id)
            ->first();

        if ($existingBlock) {
            return $this->error(
                'You have already blocked this user.',
                'block_already_exists',
                null,
                422
            );
        }

        $block = Block::create([
            'user_id' => $request->user()->id,
            'blocked_user_id' => $blockedUser->id,
        ]);

        $this->podMembershipService->dissolveSharedActivePods($request->user(), $blockedUser);

        $block->load('blockedUser:id,name,avatar_url');

        return $this->success($this->formatBlock($block), null, 201);
    }

    /**
     * GET /api/v1/blocks
     */
    public function index(Request $request): JsonResponse
    {
        $blocks = Block::query()
            ->where('user_id', $request->user()->id)
            ->with('blockedUser:id,name,avatar_url')
            ->orderByDesc('created_at')
            ->get()
            ->map(fn (Block $block) => $this->formatBlock($block));

        return $this->success($blocks);
    }

    /**
     * DELETE /api/v1/blocks/{id}
     */
    public function destroy(Block $block): JsonResponse
    {
        Gate::authorize('delete', $block);

        $block->delete();

        return $this->success(['message' => 'User unblocked successfully.']);
    }

    /**
     * @return array<string, mixed>
     */
    private function formatBlock(Block $block): array
    {
        $block->loadMissing('blockedUser:id,name,avatar_url');

        return [
            'id' => $block->id,
            'blocked_user' => [
                'id' => $block->blockedUser->id,
                'name' => $block->blockedUser->name,
                'avatar_url' => $block->blockedUser->avatar_url,
            ],
            'created_at' => $block->created_at?->toIso8601String(),
        ];
    }
}
