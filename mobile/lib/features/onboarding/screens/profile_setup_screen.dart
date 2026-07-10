import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/pair_app_bar.dart';
import 'package:pair/features/onboarding/providers/profile_setup_form_provider.dart';
import 'package:pair/features/onboarding/widgets/profile_form.dart';

class ProfileSetupScreen extends ConsumerWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const PairAppBar(
        title: 'Set up profile',
        showBack: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ProfileForm(
            submitLabel: 'Continue',
            onSubmit: () async {
              final success =
                  await ref.read(profileSetupFormProvider.notifier).submit();
              if (success && context.mounted) {
                context.go(AppRoutes.goalCategory);
              }
              return success;
            },
          ),
        ),
      ),
    );
  }
}
