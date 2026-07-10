<?php

namespace App\Traits;

use Illuminate\Http\JsonResponse;

trait ApiResponse
{
    /**
     * Return a success response.
     */
    protected function success(mixed $data = null, mixed $meta = null, int $status = 200): JsonResponse
    {
        return response()->json([
            'data' => $data,
            'meta' => $meta,
            'error' => null,
        ], $status);
    }

    /**
     * Return an error response.
     */
    protected function error(string $message, string|int $code, mixed $data = null, int $status = 400): JsonResponse
    {
        return response()->json([
            'data' => $data,
            'meta' => null,
            'error' => [
                'message' => $message,
                'code' => $code,
            ],
        ], $status);
    }
}
