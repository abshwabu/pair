import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/error_banner.dart';
import 'package:pair/core/widgets/pair_app_bar.dart';
import 'package:pair/core/widgets/primary_button.dart';
import 'package:pair/features/matching/providers/partner_match_request_provider.dart';

class MatchRequestPendingScreen extends ConsumerStatefulWidget {
  const MatchRequestPendingScreen({super.key});

  @override
  ConsumerState<MatchRequestPendingScreen> createState() =>
      _MatchRequestPendingScreenState();
}

class _MatchRequestPendingScreenState
    extends ConsumerState<MatchRequestPendingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(partnerMatchPendingProvider.notifier).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partnerMatchPendingProvider);
    final notifier = ref.read(partnerMatchPendingProvider.notifier);
    final theme = Theme.of(context);
    final request = state.request;
    final recipientName = request?.recipient?.name ?? 'your partner';

    ref.listen(partnerMatchPendingProvider, (previous, next) {
      final podId = next.request?.podId;
      if (podId != null && podId != previous?.request?.podId) {
        context.go(AppRoutes.matchFoundPath(podId));
      }
    });

    final statusText = request?.isDeclined == true
        ? '$recipientName declined your match request.'
        : request?.isCancelled == true
            ? 'Match request cancelled.'
            : 'Waiting for $recipientName to accept your request…';

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
                        request?.isDeclined == true || request?.isCancelled == true
                            ? Icons.person_off_outlined
                            : Icons.mail_outline,
                        size: 72,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        request?.isDeclined == true
                            ? 'Request declined'
                            : request?.isCancelled == true
                                ? 'Request cancelled'
                                : 'Request sent',
                        style: theme.textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        statusText,
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
                      if (state.isWaiting) ...[
                        const SizedBox(height: AppSpacing.lg),
                        const CircularProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              ),
              PrimaryButton(
                label: state.isWaiting ? 'Cancel request' : 'Back to goals',
                isLoading: state.isCancelling,
                onPressed: state.isWaiting
                    ? () async {
                        final cancelled = await notifier.cancel();
                        if (!context.mounted || !cancelled) return;
                        context.pop();
                      }
                    : () => context.go(AppRoutes.goalList),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
