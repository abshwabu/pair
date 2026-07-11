import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/pair_app_bar.dart';
import 'package:pair/core/widgets/primary_button.dart';
import 'package:pair/features/matching/providers/finding_match_provider.dart';
import 'package:pair/features/todos/models/todo_model.dart';
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
    final partnerId = partner?.user.id;

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

    final needsMyApproval = (todo.isPending && todo.createdBy != currentUserId) ||
        (todo.isPendingDeletion && todo.deletionRequestedBy != currentUserId);
    final waitingOnPartner =
        (todo.isPending && todo.createdBy == currentUserId) ||
            (todo.isPendingDeletion &&
                todo.deletionRequestedBy == currentUserId);
    final myDone = todo.isDoneBy(currentUserId);

    return Scaffold(
      appBar: PairAppBar(
        title: 'Todo',
        fallbackRoute: AppRoutes.todoListPath(podId),
        actions: [
          if (todo.isActive)
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
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (todo.isPending)
              _StatusBanner(
                message: waitingOnPartner
                    ? 'Waiting for your partner to approve this todo.'
                    : 'Your partner proposed this todo.',
              )
            else if (todo.isPendingDeletion)
              _StatusBanner(
                message: waitingOnPartner
                    ? 'Waiting for your partner to approve removal.'
                    : 'Your partner wants to remove this todo.',
              ),
            Row(
              children: [
                if (todo.isActive)
                  Checkbox(
                    value: myDone,
                    onChanged: (_) async {
                      final error = await notifier.toggleMyCompletion(
                        todo.id,
                        currentUserId: currentUserId,
                      );
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
                      decoration: myDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
            if (todo.isActive && partnerId != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                todo.isCompletedBy(partnerId)
                    ? '${partner!.user.name} has completed their check-off'
                    : '${partner!.user.name} has not checked off yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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
            if (todo.isRecurring) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Repeats', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                formatRecurrenceLabel(todo.recurrence!),
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
            if (needsMyApproval) ...[
              PrimaryButton(
                label: todo.isPendingDeletion ? 'Approve removal' : 'Approve todo',
                onPressed: () async {
                  final error = await notifier.approveTodo(todo.id);
                  if (!context.mounted) return;
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error)),
                    );
                    return;
                  }
                  context.pop();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () async {
                  final error = await notifier.rejectTodo(todo.id);
                  if (!context.mounted) return;
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error)),
                    );
                    return;
                  }
                  context.pop();
                },
                child: Text(todo.isPendingDeletion ? 'Keep todo' : 'Decline'),
              ),
            ] else if (todo.isActive) ...[
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
                onPressed: () => _confirmDeletion(
                  context,
                  notifier,
                  todo,
                  currentUserId,
                ),
                child: Text(
                  todo.requiresPartnerApproval(currentUserId)
                      ? 'Request removal'
                      : 'Delete todo',
                ),
              ),
            ] else if (waitingOnPartner) ...[
              OutlinedButton(
                onPressed: () async {
                  final error = await notifier.requestDeletion(todo.id);
                  if (!context.mounted) return;
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error)),
                    );
                    return;
                  }
                  context.pop();
                },
                child: Text(
                  todo.isPending
                      ? 'Cancel proposal'
                      : 'Cancel removal request',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeletion(
    BuildContext context,
    TodosNotifier notifier,
    TodoModel todo,
    String currentUserId,
  ) async {
    final needsApproval = todo.requiresPartnerApproval(currentUserId);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(needsApproval ? 'Request removal?' : 'Delete todo?'),
        content: Text(
          needsApproval
              ? 'Your partner must approve before this todo is removed from the pod list.'
              : 'This todo will be removed from your personal list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(needsApproval ? 'Request removal' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final error = await notifier.requestDeletion(todo.id);
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

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(message, style: theme.textTheme.bodyMedium),
      ),
    );
  }
}
