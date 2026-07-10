<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\BlockController;
use App\Http\Controllers\Api\V1\CheckInController;
use App\Http\Controllers\Api\V1\GoalController;
use App\Http\Controllers\Api\V1\MatchingController;
use App\Http\Controllers\Api\V1\MessageController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\PodController;
use App\Http\Controllers\Api\V1\ProfileController;
use App\Http\Controllers\Api\V1\ReportController;
use App\Http\Controllers\Api\V1\TodoController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::prefix('auth')->group(function () {
        Route::post('/register', [AuthController::class, 'register']);
        Route::post('/login', [AuthController::class, 'login']);

        Route::middleware('auth:sanctum')->group(function () {
            Route::post('/logout', [AuthController::class, 'logout']);
            Route::get('/me', [AuthController::class, 'me']);
        });
    });

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/profile', [ProfileController::class, 'show']);
        Route::patch('/profile', [ProfileController::class, 'update']);
        Route::patch('/profile/password', [ProfileController::class, 'updatePassword']);
        Route::delete('/profile', [ProfileController::class, 'destroy']);
        Route::patch('/profile/fcm-token', [ProfileController::class, 'updateFcmToken']);
        Route::post('/profile/avatar', [ProfileController::class, 'uploadAvatar']);
        Route::get('/notifications', [NotificationController::class, 'index']);
        Route::patch('/notifications/{notification}/read', [NotificationController::class, 'read']);

        // Goals routes
        Route::get('/goals', [GoalController::class, 'index']);
        Route::post('/goals', [GoalController::class, 'store']);
        Route::get('/goals/{goal}', [GoalController::class, 'show']);
        Route::patch('/goals/{goal}', [GoalController::class, 'update']);
        Route::delete('/goals/{goal}', [GoalController::class, 'destroy']);

        Route::post('/matching/request', [MatchingController::class, 'store']);
        Route::get('/matching/request/{podRequest}', [MatchingController::class, 'show']);
        Route::delete('/matching/request/{podRequest}', [MatchingController::class, 'destroy']);

        Route::get('/pods', [PodController::class, 'index']);
        Route::get('/pods/{pod}', [PodController::class, 'show']);
        Route::post('/pods/{pod}/leave', [PodController::class, 'leave']);

        Route::get('/pods/{pod}/todos', [TodoController::class, 'index']);
        Route::post('/pods/{pod}/todos', [TodoController::class, 'store']);
        Route::patch('/pods/{pod}/todos/{todo}', [TodoController::class, 'update'])->scopeBindings();
        Route::delete('/pods/{pod}/todos/{todo}', [TodoController::class, 'destroy'])->scopeBindings();

        Route::get('/pods/{pod}/messages', [MessageController::class, 'index']);
        Route::post('/pods/{pod}/messages', [MessageController::class, 'store']);
        Route::post('/pods/{pod}/messages/attachments', [MessageController::class, 'uploadAttachment']);
        Route::post('/pods/{pod}/typing', [MessageController::class, 'typing']);

        Route::get('/pods/{pod}/check-ins', [CheckInController::class, 'index']);
        Route::post('/pods/{pod}/check-ins', [CheckInController::class, 'store']);
        Route::get('/pods/{pod}/streak', [CheckInController::class, 'streak']);
        Route::post('/pods/{pod}/nudge', [CheckInController::class, 'nudge']);

        Route::post('/reports', [ReportController::class, 'store']);
        Route::middleware('admin')->group(function () {
            Route::get('/reports', [ReportController::class, 'index']);
            Route::patch('/reports/{report}', [ReportController::class, 'update']);
        });

        Route::get('/blocks', [BlockController::class, 'index']);
        Route::post('/blocks', [BlockController::class, 'store']);
        Route::delete('/blocks/{block}', [BlockController::class, 'destroy']);
    });
});
