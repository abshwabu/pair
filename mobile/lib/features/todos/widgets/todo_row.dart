import 'package:flutter/material.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/features/pods/models/pod_model.dart';
import 'package:pair/features/todos/models/todo_model.dart';
import 'package:pair/features/todos/providers/todos_provider.dart';
import 'package:pair/features/todos/widgets/assignee_chip.dart';

class TodoRow extends StatelessWidget {
  const TodoRow({
    super.key,
    required this.todo,
    required this.currentUserId,
    required this.partner,
    required this.onToggle,
    this.onTap,
    this.showCheckbox = true,
  });

  final TodoModel todo;
  final String currentUserId;
  final PodMemberModel? partner;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onTap;
  final bool showCheckbox;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final partnerId = partner?.user.id;
    final partnerCompleted =
        partnerId != null && todo.isCompletedBy(partnerId);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showCheckbox && todo.isActive)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Checkbox(
                  value: todo.myCompleted,
                  onChanged: (value) {
                    if (value != null) onToggle(value);
                  },
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      decoration: todo.myCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: todo.myCompleted
                          ? theme.colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                  if (todo.dueDate != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Due ${formatTodoDueDate(todo.dueDate!)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  if (todo.isActive && partnerId != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      partnerCompleted
                          ? '${partner!.user.name} completed'
                          : '${partner!.user.name} not done yet',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: partnerCompleted
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            assigneeChipForTodo(
              assignedTo: todo.assignedTo,
              currentUserId: currentUserId,
              partner: partner,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}
