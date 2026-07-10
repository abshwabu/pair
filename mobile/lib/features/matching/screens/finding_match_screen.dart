import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/error_banner.dart';
import 'package:pair/core/widgets/primary_button.dart';
import 'package:pair/features/matching/providers/finding_match_provider.dart';

class FindingMatchScreen extends ConsumerStatefulWidget {
  const FindingMatchScreen({super.key});

  @override
  ConsumerState<FindingMatchScreen> createState() => _FindingMatchScreenState();
}

class _FindingMatchScreenState extends ConsumerState<FindingMatchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(findingMatchProvider.notifier).start();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(findingMatchProvider);
    final notifier = ref.read(findingMatchProvider.notifier);
    final theme = Theme.of(context);

    ref.listen<FindingMatchState>(findingMatchProvider, (previous, next) {
      final podId = next.matchedPodId;
      if (podId != null && podId != previous?.matchedPodId) {
        context.go(AppRoutes.matchFoundPath(podId));
      }
    });

    final statusMessage =
        findingMatchStatusMessages[state.statusMessageIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finding a match'),
        automaticallyImplyLeading: false,
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
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primaryContainer,
                          ),
                          child: Icon(
                            Icons.people_outline,
                            size: 56,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Looking for your partner',
                        style: theme.textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          statusMessage,
                          key: ValueKey(statusMessage),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (state.isWaiting)
                        const CircularProgressIndicator(),
                    ],
                  ),
                ),
              ),
              PrimaryButton(
                label: 'Cancel',
                isLoading: state.isCancelling,
                onPressed: state.isWaiting || state.isCancelling
                    ? () async {
                        final cancelled = await notifier.cancel();
                        if (!context.mounted || !cancelled) return;
                        context.go(AppRoutes.matchingPrefs);
                      }
                    : () => context.go(AppRoutes.matchingPrefs),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
