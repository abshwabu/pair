<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('partner_match_requests', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('requester_user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUuid('requester_goal_id')->constrained('goals')->cascadeOnDelete();
            $table->foreignUuid('recipient_user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUuid('recipient_goal_id')->constrained('goals')->cascadeOnDelete();
            $table->enum('status', ['pending', 'accepted', 'declined', 'cancelled'])->default('pending');
            $table->integer('timezone_tolerance_hours')->default(3);
            $table->foreignUuid('pod_id')->nullable()->constrained('pods')->nullOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('partner_match_requests');
    }
};
