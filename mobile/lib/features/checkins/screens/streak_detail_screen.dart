import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/features/checkins/models/check_in_model.dart';
import 'package:pair/features/checkins/providers/streak_provider.dart';
import 'package:pair/features/checkins/widgets/streak_badge.dart';

class StreakDetailScreen extends ConsumerWidget {
  const StreakDetailScreen({super.key, required this.podId});

  final String podId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(streakDetailProvider(podId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Streak')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Unable to load streak details.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (detail) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      StreakBadge(currentStreak: detail.streak.currentStreak),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              label: 'Current',
                              value:
                                  '${detail.streak.currentStreak} day${detail.streak.currentStreak == 1 ? '' : 's'}',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _StatTile(
                              label: 'Best',
                              value:
                                  '${detail.streak.bestStreak} day${detail.streak.bestStreak == 1 ? '' : 's'}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Check-in history', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              if (detail.dayGroups.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'No check-ins yet. Complete your first check-in from pod home.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ...detail.dayGroups.map(
                  (day) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _CheckInDayRow(day: day),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _CheckInDayRow extends StatelessWidget {
  const _CheckInDayRow({required this.day});

  final CheckInDayGroup day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBoth = day.bothCheckedIn;
    final statusLabel = isBoth
        ? 'Both checked in'
        : day.onlyOneCheckedIn
            ? 'One member checked in'
            : 'No check-ins';
    final statusColor = isBoth
        ? AppColors.success
        : day.onlyOneCheckedIn
            ? AppColors.warning
            : theme.colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isBoth
                      ? Icons.people_outline
                      : Icons.person_outline,
                  size: 18,
                  color: statusColor,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    _formatDate(day.date),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  statusLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: statusColor,
                  ),
                ),
              ],
            ),
            if (day.checkIns.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              ...day.checkIns.map(
                (checkIn) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check, size: 16),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              checkIn.user.name,
                              style: theme.textTheme.bodyMedium,
                            ),
                            if (checkIn.note != null &&
                                checkIn.note!.isNotEmpty)
                              Text(
                                checkIn.note!,
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    final parts = isoDate.split('-');
    if (parts.length != 3) return isoDate;
    final year = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    final dayNum = int.tryParse(parts[2]) ?? 0;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final monthLabel =
        month >= 1 && month <= 12 ? months[month - 1] : parts[1];
    return '$monthLabel $dayNum, $year';
  }
}
