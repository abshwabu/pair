import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/error_banner.dart';
import 'package:pair/core/widgets/pair_app_bar.dart';
import 'package:pair/core/widgets/primary_button.dart';
import 'package:pair/features/matching/providers/partner_match_request_provider.dart';

class MatchRequestPendingScreen extends ConsumerWidget {
  const MatchRequestPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(partnerMatchPendingProvider);
    final theme = Theme.of(context);
    final request = state.request;
    final recipientName = request?.recipient?.name ?? 'your partner';

    return Scaffold(
      appBar: const PairAppBar(
        title: 'Match request sent',
        fallbackRoute: AppRoutes.goalList,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              if (state.error != null) ...[
                ErrorBanner(message: state.error!),
                const SizedBox(height: AppSpacing.md),
              ],
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 72,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Request sent',
                        style: theme.textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Your match request was sent to $recipientName. '
                        'We\'ll notify you when they respond.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (request?.recipientGoal != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              children: [
                                Text(
                                  'Their goal',
                                  style: theme.textTheme.labelMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  request!.recipientGoal!.title,
                                  style: theme.textTheme.titleMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              PrimaryButton(
                label: 'Back to goals',
                onPressed: () => context.go(AppRoutes.goalList),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
