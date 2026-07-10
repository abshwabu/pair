<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\UpdateFcmTokenRequest;
use App\Http\Requests\UpdatePasswordRequest;
use App\Http\Requests\UpdateProfileRequest;
use App\Http\Requests\UploadAvatarRequest;
use App\Services\AccountDeletionService;
use App\Support\UploadStorage;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class ProfileController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly AccountDeletionService $accountDeletionService,
    ) {}

    /**
     * GET /api/v1/profile
     */
    public function show(Request $request): JsonResponse
    {
        return $this->success($request->user());
    }

    /**
     * PATCH /api/v1/profile
     */
    public function update(UpdateProfileRequest $request): JsonResponse
    {
        $user = $request->user();
        $user->update($request->validated());

        return $this->success($user);
    }

    /**
     * POST /api/v1/profile/avatar
     */
    public function uploadAvatar(UploadAvatarRequest $request): JsonResponse
    {
        $user = $request->user();
        $file = $request->file('avatar');

        $upload = UploadStorage::storePublicUrl($file, "avatars/{$user->id}");

        $user->update([
            'avatar_url' => $upload['url'],
        ]);

        return $this->success($user);
    }

    /**
     * PATCH /api/v1/profile/fcm-token
     */
    public function updateFcmToken(UpdateFcmTokenRequest $request): JsonResponse
    {
        $user = $request->user();
        $user->update([
            'fcm_token' => $request->validated('fcm_token'),
        ]);

        return $this->success($user);
    }

    /**
     * PATCH /api/v1/profile/password
     */
    public function updatePassword(UpdatePasswordRequest $request): JsonResponse
    {
        $user = $request->user();

        if (! Hash::check($request->validated('current_password'), $user->password)) {
            return $this->error(
                'The current password is incorrect.',
                'invalid_current_password',
                null,
                422
            );
        }

        $user->update([
            'password' => $request->validated('password'),
        ]);

        return $this->success($user);
    }

    /**
     * DELETE /api/v1/profile
     */
    public function destroy(Request $request): JsonResponse
    {
        $user = $request->user();
        $this->accountDeletionService->delete($user);

        return $this->success(['message' => 'Account deleted successfully.']);
    }
}
