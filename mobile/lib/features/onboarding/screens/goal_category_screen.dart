import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/home_back_scope.dart';
import 'package:pair/core/widgets/main_bottom_nav.dart';
import 'package:pair/core/widgets/pair_app_bar.dart';
import 'package:pair/features/onboarding/providers/goal_category_provider.dart';

class GoalCategoryScreen extends ConsumerWidget {
  const GoalCategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(goalCategoryProvider);
    final notifier = ref.read(goalCategoryProvider.notifier);
    final theme = Theme.of(context);

    return HomeBackScope(
      child: Scaffold(
        appBar: const PairAppBar(
          title: 'Choose a goal',
          showBack: false,
        ),
        bottomNavigationBar: const MainBottomNav(currentTab: MainTab.home),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'What are you working on?',
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Pick a category to find the right accountability partner.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    children: goalCategories.map((category) {
                      final isSelected = state.selectedCategory == category.id;

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            notifier.selectCategory(category.id);
                            context.push(AppRoutes.goalList);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  category.icon,
                                  size: 32,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  category.label,
                                  style: theme.textTheme.titleMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
