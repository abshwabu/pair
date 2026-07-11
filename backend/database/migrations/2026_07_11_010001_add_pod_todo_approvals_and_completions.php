<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('todos', function (Blueprint $table) {
            $table->string('status')->default('pending')->after('pod_id');
            $table->foreignUuid('deletion_requested_by')
                ->nullable()
                ->after('created_by')
                ->constrained('users')
                ->nullOnDelete();
        });

        DB::table('todos')->update(['status' => 'active']);

        Schema::create('todo_completions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('todo_id')->constrained('todos')->cascadeOnDelete();
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->timestamp('completed_at');
            $table->timestamps();

            $table->unique(['todo_id', 'user_id']);
        });

        $completedTodos = DB::table('todos')
            ->where('is_done', true)
            ->get(['id', 'created_by', 'completed_at']);

        foreach ($completedTodos as $todo) {
            DB::table('todo_completions')->insert([
                'id' => (string) \Illuminate\Support\Str::uuid(),
                'todo_id' => $todo->id,
                'user_id' => $todo->created_by,
                'completed_at' => $todo->completed_at ?? now(),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('todo_completions');

        Schema::table('todos', function (Blueprint $table) {
            $table->dropConstrainedForeignId('deletion_requested_by');
            $table->dropColumn('status');
        });
    }
};
