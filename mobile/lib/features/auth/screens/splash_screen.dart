import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/error_banner.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/auth_state.dart';
import 'package:pair/core/notifications/push_notification_service.dart';
import 'package:pair/features/auth/providers/splash_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final route = await ref.read(splashProvider.notifier).bootstrap();
    if (!mounted || route == null) return;

    notifyAuthChanged(ref);
    if (route != AppRoutes.login) {
      await ref.read(pushNotificationServiceProvider).registerTokenIfAuthenticated();
    }
    if (!mounted) return;
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(splashProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Pair',
                  style: theme.textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Accountability, together.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (state.isLoading) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  const CircularProgressIndicator(),
                ] else if (state.error != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  ErrorBanner(message: state.error!),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: _bootstrap,
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
