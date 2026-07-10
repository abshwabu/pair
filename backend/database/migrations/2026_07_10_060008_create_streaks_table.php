<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('streaks', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('pod_id')->unique()->constrained('pods')->cascadeOnDelete();
            $table->integer('current_streak')->default(0);
            $table->integer('best_streak')->default(0);
            $table->date('last_check_in_date')->nullable();
            $table->timestamp('updated_at')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('streaks');
    }
};
