import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/auth_state.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/error_banner.dart';
import 'package:pair/core/widgets/primary_button.dart';
import 'package:pair/features/auth/providers/signup_form_provider.dart';

class SignupScreen extends ConsumerWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(signupFormProvider);
    final notifier = ref.read(signupFormProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Join Pair',
                style: theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Create an account to find your accountability partner.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (form.error != null) ...[
                ErrorBanner(
                  message: form.error!,
                  onDismiss: () => notifier.setName(form.name),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              TextField(
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Name',
                  errorText: form.nameError,
                ),
                onChanged: notifier.setName,
              ),
              const SizedBox(height: AppSpacing.md),
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
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: form.passwordError,
                ),
                onChanged: notifier.setPassword,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Confirm password',
                  errorText: form.confirmPasswordError,
                ),
                onChanged: notifier.setConfirmPassword,
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Create account',
                isLoading: form.isLoading,
                onPressed: () async {
                  final route = await notifier.submit();
                  if (!context.mounted || route == null) return;
                  notifyAuthChanged(ref);
                  context.go(route);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: form.isLoading
                    ? null
                    : () => context.go(AppRoutes.login),
                child: const Text('Already have an account? Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
