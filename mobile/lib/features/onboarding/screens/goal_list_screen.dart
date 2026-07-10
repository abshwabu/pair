import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/error_banner.dart';
import 'package:pair/features/onboarding/providers/goal_category_provider.dart';
import 'package:pair/features/onboarding/providers/goal_detail_form_provider.dart';
import 'package:pair/features/onboarding/providers/goal_list_provider.dart';
import 'package:pair/features/onboarding/providers/onboarding_session_provider.dart';
import 'package:pair/features/onboarding/services/goal_service.dart';

class GoalListScreen extends ConsumerWidget {
  const GoalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(onboardingSessionProvider).selectedCategory;
    final theme = Theme.of(context);

    if (category == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRoutes.goalCategory);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final categoryLabel = goalCategories
        .where((option) => option.id == category)
        .map((option) => option.label)
        .firstOrNull;

    final listState = ref.watch(goalListProvider(category));
    final sessionNotifier = ref.read(onboardingSessionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryLabel ?? 'Your goals'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(goalDetailFormProvider.notifier).reset();
          context.push(AppRoutes.goalDetail);
        },
        icon: const Icon(Icons.add),
        label: const Text('Create goal'),
      ),
      body: SafeArea(
        child: listState.isLoading && !listState.hasLoaded
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(goalListProvider(category).notifier).load(),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Text(
                      'Pick a goal',
                      style: theme.textTheme.headlineLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Choose one you already have, or create a new one if nothing fits.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (listState.error != null) ...[
                      ErrorBanner(message: listState.error!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (listState.hasLoaded && listState.goals.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            children: [
                              Icon(
                                Icons.flag_outlined,
                                size: 40,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'No goals in this category yet',
                                style: theme.textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Tap Create goal to define one that fits you.',
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...listState.goals.map(
                        (goal) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _GoalCard(
                            goal: goal,
                            onTap: () {
                              sessionNotifier.setCreatedGoalId(goal.id);
                              context.go(AppRoutes.matchingPrefs);
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.onTap});

  final GoalModel goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      goal.pace[0].toUpperCase() + goal.pace.substring(1),
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
              if (goal.targetDescription.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  goal.targetDescription,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
