import 'package:flutter/material.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/features/pods/models/pod_model.dart';

class AssigneeChip extends StatelessWidget {
  const AssigneeChip({
    super.key,
    required this.label,
    this.avatarUrl,
    this.compact = false,
  });

  final String label;
  final String? avatarUrl;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = label.isNotEmpty ? label[0].toUpperCase() : '?';
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    final radius = compact ? 10.0 : 12.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
            child: hasAvatar
                ? null
                : Text(
                    initials,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
          ),
          if (!compact) ...[
            const SizedBox(width: AppSpacing.xxs),
            Text(label, style: theme.textTheme.labelMedium),
          ],
        ],
      ),
    );
  }
}

AssigneeChip assigneeChipForTodo({
  required String? assignedTo,
  required String currentUserId,
  required PodMemberModel? partner,
  bool compact = false,
}) {
  if (assignedTo == null) {
    return AssigneeChip(label: 'Both', compact: compact);
  }

  if (assignedTo == currentUserId) {
    return AssigneeChip(label: 'Me', compact: compact);
  }

  if (partner != null && assignedTo == partner.user.id) {
    return AssigneeChip(
      label: partner.user.name,
      avatarUrl: partner.user.avatarUrl,
      compact: compact,
    );
  }

  return AssigneeChip(label: 'Partner', compact: compact);
}
