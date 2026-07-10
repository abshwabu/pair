import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/primary_button.dart';
import 'package:pair/features/checkins/providers/streak_provider.dart';

class StreakRecoveryScreen extends ConsumerStatefulWidget {
  const StreakRecoveryScreen({super.key, required this.podId});

  final String podId;

  @override
  ConsumerState<StreakRecoveryScreen> createState() =>
      _StreakRecoveryScreenState();
}

class _StreakRecoveryScreenState extends ConsumerState<StreakRecoveryScreen> {
  bool _nudgeSent = false;

  @override
  Widget build(BuildContext context) {
    final streakState = ref.watch(streakProvider(widget.podId));
    final notifier = ref.read(streakProvider(widget.podId).notifier);
    final theme = Theme.of(context);
    final streak = streakState.streak;

    if (streakState.isLoading && !streakState.hasLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Streak recovery')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (streak == null || !streak.isBroken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.podHomePath(widget.podId));
      });
      return Scaffold(
        appBar: AppBar(title: const Text('Streak recovery')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Streak recovery')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.local_fire_department_outlined,
                size: 72,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Every streak starts with day one',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'You and your partner built a ${streak.bestStreak}-day streak before. '
                'Missed days happen — what matters is showing up again together.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (_nudgeSent)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    'Your partner has been nudged.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.success,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (streakState.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    streakState.error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              PrimaryButton(
                label: 'Nudge your partner',
                isLoading: streakState.isNudging,
                onPressed: streakState.isNudging
                    ? null
                    : () async {
                        final error = await notifier.nudgePartner();
                        if (!mounted) return;
                        if (error == null) {
                          setState(() => _nudgeSent = true);
                        }
                      },
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () =>
                    context.go(AppRoutes.podHomePath(widget.podId)),
                child: const Text('Back to pod home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
