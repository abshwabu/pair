import 'package:flutter/material.dart';
import 'package:pair/core/theme/app_theme.dart';

class DailyCheckInCard extends StatelessWidget {
  const DailyCheckInCard({
    super.key,
    required this.onCheckIn,
    required this.onDismiss,
  });

  final VoidCallback onCheckIn;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Check in for today',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Log your progress and keep your streak alive.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: onCheckIn,
                    child: const Text('Check in now'),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 20),
              tooltip: 'Dismiss',
            ),
          ],
        ),
      ),
    );
  }
}

class StreakRecoveryCard extends StatelessWidget {
  const StreakRecoveryCard({
    super.key,
    required this.bestStreak,
    required this.onViewRecovery,
  });

  final int bestStreak;
  final VoidCallback onViewRecovery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department_outlined,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your streak ended',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'You reached $bestStreak day${bestStreak == 1 ? '' : 's'} before. Start fresh together.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: onViewRecovery,
                    child: const Text('Get back on track'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
