<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\GoalController;
use App\Http\Controllers\Api\V1\MatchingController;
use App\Http\Controllers\Api\V1\PodController;
use App\Http\Controllers\Api\V1\ProfileController;
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
        Route::post('/profile/avatar', [ProfileController::class, 'uploadAvatar']);

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
    });
});
