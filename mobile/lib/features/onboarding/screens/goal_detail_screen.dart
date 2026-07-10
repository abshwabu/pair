import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/error_banner.dart';
import 'package:pair/core/widgets/pair_app_bar.dart';
import 'package:pair/core/widgets/primary_button.dart';
import 'package:pair/features/onboarding/providers/goal_detail_form_provider.dart';
import 'package:pair/features/onboarding/providers/goal_list_provider.dart';
import 'package:pair/features/onboarding/providers/onboarding_session_provider.dart';

class GoalDetailScreen extends ConsumerStatefulWidget {
  const GoalDetailScreen({super.key});

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(goalDetailFormProvider);
    final notifier = ref.read(goalDetailFormProvider.notifier);
    final category = ref.watch(onboardingSessionProvider).selectedCategory;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PairAppBar(
        title: 'Create goal',
        fallbackRoute: AppRoutes.goalList,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Define your goal',
                style: theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                category != null
                    ? 'Category: ${category[0].toUpperCase()}${category.substring(1)}'
                    : 'Select a category first.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (form.error != null) ...[
                ErrorBanner(
                  message: form.error!,
                  onDismiss: notifier.clearError,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  errorText: form.titleError,
                ),
                onChanged: notifier.setTitle,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Target description',
                  alignLabelWithHint: true,
                  errorText: form.targetDescriptionError,
                ),
                onChanged: notifier.setTargetDescription,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Pace', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<String>(
                segments: goalPaceOptions
                    .map(
                      (pace) => ButtonSegment<String>(
                        value: pace,
                        label: Text(
                          pace[0].toUpperCase() + pace.substring(1),
                        ),
                      ),
                    )
                    .toList(),
                selected: {form.pace},
                onSelectionChanged: form.isLoading
                    ? null
                    : (selection) => notifier.setPace(selection.first),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Continue',
                isLoading: form.isLoading,
                onPressed: () async {
                  final success = await notifier.submit(category);
                  if (!context.mounted || !success) return;
                  if (category != null) {
                    ref.invalidate(goalListProvider(category));
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Goal created — others in this category can now see it.',
                      ),
                    ),
                  );
                  context.pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
