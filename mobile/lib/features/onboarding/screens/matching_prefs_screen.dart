import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/error_banner.dart';
import 'package:pair/core/widgets/pair_app_bar.dart';
import 'package:pair/core/widgets/primary_button.dart';
import 'package:pair/features/onboarding/data/onboarding_options.dart';
import 'package:pair/features/onboarding/providers/matching_prefs_form_provider.dart';

class MatchingPrefsScreen extends ConsumerWidget {
  const MatchingPrefsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(matchingPrefsFormProvider);
    final notifier = ref.read(matchingPrefsFormProvider.notifier);
    final theme = Theme.of(context);

    if (form.isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const PairAppBar(
        title: 'Matching preferences',
        fallbackRoute: AppRoutes.goalList,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Find the right partner',
                style: theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Set how flexible you are on timezone and language.',
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
              Text(
                'Timezone tolerance',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${form.timezoneToleranceHours} hour${form.timezoneToleranceHours == 1 ? '' : 's'}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              Slider(
                value: form.timezoneToleranceHours.toDouble(),
                min: 0,
                max: 12,
                divisions: 12,
                label: '${form.timezoneToleranceHours}h',
                onChanged: form.isLoading
                    ? null
                    : (value) => notifier.setTimezoneTolerance(value.round()),
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                initialValue: LanguageOptions.labels.containsKey(form.language)
                    ? form.language
                    : 'en',
                decoration: const InputDecoration(labelText: 'Preferred language'),
                items: LanguageOptions.labels.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: form.isLoading
                    ? null
                    : (value) {
                        if (value != null) notifier.setLanguage(value);
                      },
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Find my partner',
                isLoading: form.isLoading,
                onPressed: () async {
                  final success = await notifier.submit();
                  if (!context.mounted || !success) return;
                  context.push(AppRoutes.findingMatch);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
