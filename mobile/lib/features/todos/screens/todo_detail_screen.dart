import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/pair_app_bar.dart';
import 'package:pair/core/widgets/primary_button.dart';
import 'package:pair/features/matching/providers/finding_match_provider.dart';
import 'package:pair/features/todos/providers/todos_provider.dart';
import 'package:pair/features/todos/widgets/assignee_chip.dart';
import 'package:pair/features/todos/widgets/todo_form_sheet.dart';

class TodoDetailScreen extends ConsumerWidget {
  const TodoDetailScreen({
    super.key,
    required this.podId,
    required this.todoId,
  });

  final String podId;
  final String todoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosState = ref.watch(todosProvider(podId));
    final notifier = ref.read(todosProvider(podId).notifier);
    final userAsync = ref.watch(currentUserProvider);
    final podAsync = ref.watch(podDetailProvider(podId));
    final theme = Theme.of(context);

    final currentUserId = userAsync.asData?.value.id;
    final partner = currentUserId != null
        ? podAsync.asData?.value.activePartnerFor(currentUserId)
        : null;
    final todo = notifier.todoById(todoId);

    if (currentUserId == null || todosState.isLoading && todo == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (todo == null) {
      return Scaffold(
        appBar: PairAppBar(
          title: 'Todo',
          fallbackRoute: AppRoutes.todoListPath(podId),
        ),
        body: Center(
          child: Text(
            'Todo not found.',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: PairAppBar(
        title: 'Todo',
        fallbackRoute: AppRoutes.todoListPath(podId),
        actions: [
          IconButton(
            onPressed: () => showTodoFormSheet(
              context: context,
              ref: ref,
              podId: podId,
              currentUserId: currentUserId,
              partnerUserId: partner?.user.id,
              existing: todo,
            ),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: () => _confirmDelete(context, ref, notifier),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Row(
              children: [
                Checkbox(
                  value: todo.isDone,
                  onChanged: (_) async {
                    final error = await notifier.toggleDone(todo.id);
                    if (error != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                    }
                  },
                ),
                Expanded(
                  child: Text(
                    todo.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      decoration:
                          todo.isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            assigneeChipForTodo(
              assignedTo: todo.assignedTo,
              currentUserId: currentUserId,
              partner: partner,
            ),
            if (todo.dueDate != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Due date', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                formatTodoDueDate(todo.dueDate!),
                style: theme.textTheme.bodyLarge,
              ),
            ],
            if (todo.notes != null && todo.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Notes', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(todo.notes!, style: theme.textTheme.bodyLarge),
            ],
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Edit todo',
              onPressed: () => showTodoFormSheet(
                context: context,
                ref: ref,
                podId: podId,
                currentUserId: currentUserId,
                partnerUserId: partner?.user.id,
                existing: todo,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => _confirmDelete(context, ref, notifier),
              child: const Text('Delete todo'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TodosNotifier notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete todo?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final error = await notifier.deleteTodo(todoId);
    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    context.pop();
  }
}
