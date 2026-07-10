import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/features/account/providers/profile_provider.dart';
import 'package:pair/features/onboarding/providers/profile_setup_form_provider.dart';
import 'package:pair/features/onboarding/widgets/profile_form.dart';

class ProfileEditScreen extends ConsumerWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ProfileForm(
            showHeader: false,
            submitLabel: 'Save changes',
            onSubmit: () async {
              final success =
                  await ref.read(profileSetupFormProvider.notifier).submit();
              if (success) {
                ref.invalidate(profileProvider);
                if (context.mounted) context.pop();
              }
              return success;
            },
          ),
        ),
      ),
    );
  }
}
