import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/features/pods/models/pod_model.dart';
import 'package:pair/features/todos/providers/todos_provider.dart';
import 'package:pair/features/todos/widgets/todo_row.dart';

class OpenTodosPreview extends ConsumerWidget {
  const OpenTodosPreview({
    super.key,
    required this.podId,
    required this.currentUserId,
    required this.partner,
  });

  final String podId;
  final String currentUserId;
  final PodMemberModel? partner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosState = ref.watch(todosProvider(podId));
    final notifier = ref.read(todosProvider(podId).notifier);
    final theme = Theme.of(context);

    if (todosState.isLoading && !todosState.hasLoaded) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final openTodos = notifier.openTodos(currentUserId: currentUserId, limit: 3);

    if (openTodos.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Icon(
                Icons.checklist_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No open todos yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < openTodos.length; i++) ...[
            TodoRow(
              todo: openTodos[i],
              currentUserId: currentUserId,
              partner: partner,
              onToggle: (_) async {
                final error =
                    await notifier.toggleMyCompletion(openTodos[i].id);
                if (error != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                }
              },
              onTap: () => context.push(
                AppRoutes.todoDetailPath(podId, openTodos[i].id),
              ),
            ),
            if (i < openTodos.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}
