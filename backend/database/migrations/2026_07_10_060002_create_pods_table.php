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
        Schema::create('pods', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('goal_category');
            $table->enum('status', ['pending', 'active', 'completed', 'dissolved'])->default('pending');
            $table->integer('capacity')->default(2);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pods');
    }
};
