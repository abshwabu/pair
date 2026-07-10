import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/error_banner.dart';
import 'package:pair/core/widgets/pair_app_bar.dart';
import 'package:pair/features/onboarding/providers/goal_category_provider.dart';
import 'package:pair/features/onboarding/providers/goal_detail_form_provider.dart';
import 'package:pair/features/onboarding/providers/goal_list_provider.dart';
import 'package:pair/features/onboarding/providers/onboarding_session_provider.dart';
import 'package:pair/features/onboarding/services/goal_service.dart';
import 'package:pair/features/pods/widgets/partner_avatar.dart';

class GoalListScreen extends ConsumerWidget {
  const GoalListScreen({super.key});

  Future<void> _onOwnGoalTap(
    BuildContext context,
    WidgetRef ref,
    GoalModel goal,
  ) async {
    final sessionNotifier = ref.read(onboardingSessionProvider.notifier);
    sessionNotifier.setCreatedGoalId(goal.id);
    sessionNotifier.clearTargetGoalId();
    context.push(AppRoutes.matchingPrefs);
  }

  Future<void> _onCommunityGoalTap(
    BuildContext context,
    WidgetRef ref,
    GoalModel communityGoal,
    List<GoalModel> myGoals,
  ) async {
    if (myGoals.isEmpty) {
      final create = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Create your goal first'),
          content: const Text(
            'You need your own goal in this category before matching '
            'with someone else.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Create goal'),
            ),
          ],
        ),
      );

      if (create == true && context.mounted) {
        ref.read(goalDetailFormProvider.notifier).reset();
        context.push(AppRoutes.goalDetail);
      }
      return;
    }

    String? ownGoalId;
    if (myGoals.length == 1) {
      ownGoalId = myGoals.first.id;
    } else if (context.mounted) {
      ownGoalId = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Which of your goals do you want to match with?',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              ...myGoals.map(
                (goal) => ListTile(
                  title: Text(goal.title),
                  subtitle: goal.targetDescription.isNotEmpty
                      ? Text(
                          goal.targetDescription,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(goal.id),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      );
    }

    if (ownGoalId == null || !context.mounted) return;

    final sessionNotifier = ref.read(onboardingSessionProvider.notifier);
    sessionNotifier.setCreatedGoalId(ownGoalId);
    sessionNotifier.setTargetGoalId(communityGoal.id);
    context.push(AppRoutes.matchingPrefs);
  }

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

    return Scaffold(
      appBar: PairAppBar(
        title: categoryLabel ?? 'Your goals',
        fallbackRoute: AppRoutes.goalCategory,
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
                      'Choose one of yours to match on, or tap someone else\'s goal to pair with them.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (listState.error != null) ...[
                      ErrorBanner(message: listState.error!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Text('Your goals', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    if (listState.hasLoaded && listState.myGoals.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            'No goals yet. Tap Create goal to add one others can discover.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ...listState.myGoals.map(
                        (goal) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _GoalCard(
                            goal: goal,
                            actionLabel: 'Tap to match with anyone',
                            onTap: () => _onOwnGoalTap(context, ref, goal),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'From others',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'People actively looking for a partner in this category.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (listState.hasLoaded &&
                        listState.communityGoals.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            'No one is searching in this category yet. '
                            'Create a goal and start matching!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ...listState.communityGoals.map(
                        (goal) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _GoalCard(
                            goal: goal,
                            actionLabel: 'Tap to send a match request',
                            onTap: () => _onCommunityGoalTap(
                              context,
                              ref,
                              goal,
                              listState.myGoals,
                            ),
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
  const _GoalCard({
    required this.goal,
    required this.actionLabel,
    required this.onTap,
  });

  final GoalModel goal;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final owner = goal.owner;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (owner != null && !goal.isMine) ...[
                Row(
                  children: [
                    PartnerAvatar(
                      name: owner.name,
                      avatarUrl: owner.avatarUrl,
                      radius: 14,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(owner.name, style: theme.textTheme.labelMedium),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
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
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                actionLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
