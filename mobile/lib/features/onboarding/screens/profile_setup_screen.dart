import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/error_banner.dart';
import 'package:pair/core/widgets/primary_button.dart';
import 'package:pair/features/onboarding/data/onboarding_options.dart';
import 'package:pair/features/onboarding/providers/profile_setup_form_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(profileSetupFormProvider);
    final notifier = ref.read(profileSetupFormProvider.notifier);
    final theme = Theme.of(context);

    if (!form.isInitializing && _nameController.text != form.name) {
      _nameController.text = form.name;
    }

    if (form.isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final timezoneItems = {
      ...TimezoneOptions.values,
      if (!TimezoneOptions.values.contains(form.timezone)) form.timezone,
    }.toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Set up profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tell us about you',
                style: theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Add a photo and confirm your details.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (form.error != null) ...[
                ErrorBanner(message: form.error!),
                const SizedBox(height: AppSpacing.md),
              ],
              Center(
                child: GestureDetector(
                  onTap: form.isLoading
                      ? null
                      : () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 1024,
                            maxHeight: 1024,
                            imageQuality: 85,
                          );
                          if (image != null) {
                            notifier.setAvatarPath(image.path);
                          }
                        },
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: notifier.avatarFile != null
                        ? FileImage(notifier.avatarFile!)
                        : null,
                    child: notifier.avatarFile == null
                        ? Icon(
                            Icons.camera_alt_outlined,
                            size: 32,
                            color: theme.colorScheme.onPrimaryContainer,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(
                  'Tap to add photo',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Name',
                  errorText: form.nameError,
                ),
                onChanged: notifier.setName,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: form.timezone,
                decoration: const InputDecoration(labelText: 'Timezone'),
                items: timezoneItems
                    .map(
                      (tz) => DropdownMenuItem(value: tz, child: Text(tz)),
                    )
                    .toList(),
                onChanged: form.isLoading
                    ? null
                    : (value) {
                        if (value != null) notifier.setTimezone(value);
                      },
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: LanguageOptions.labels.containsKey(form.language)
                    ? form.language
                    : 'en',
                decoration: const InputDecoration(labelText: 'Language'),
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
                label: 'Continue',
                isLoading: form.isLoading,
                onPressed: () async {
                  final success = await notifier.submit();
                  if (!context.mounted || !success) return;
                  context.go(AppRoutes.goalCategory);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
