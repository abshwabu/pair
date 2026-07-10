import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/auth_state.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/error_banner.dart';
import 'package:pair/core/widgets/primary_button.dart';
import 'package:pair/core/notifications/push_notification_service.dart';
import 'package:pair/features/auth/providers/login_form_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(loginFormProvider);
    final notifier = ref.read(loginFormProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome back',
                style: theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Sign in to continue your accountability journey.',
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
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  labelText: 'Email',
                  errorText: form.emailError,
                ),
                onChanged: notifier.setEmail,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: form.passwordError,
                ),
                onChanged: notifier.setPassword,
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Sign in',
                isLoading: form.isLoading,
                onPressed: () async {
                  final route = await notifier.submit();
                  if (!context.mounted || route == null) return;
                  notifyAuthChanged(ref);
                  await ref
                      .read(pushNotificationServiceProvider)
                      .registerTokenIfAuthenticated();
                  if (!context.mounted) return;
                  context.go(route);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: form.isLoading
                    ? null
                    : () => context.go(AppRoutes.signup),
                child: const Text("Don't have an account? Sign up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
