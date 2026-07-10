import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/error_banner.dart';
import 'package:pair/core/widgets/primary_button.dart';
import 'package:pair/features/onboarding/data/onboarding_options.dart';
import 'package:pair/features/onboarding/providers/profile_setup_form_provider.dart';

class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({
    super.key,
    required this.submitLabel,
    required this.onSubmit,
    this.showHeader = true,
    this.headerTitle = 'Tell us about you',
    this.headerSubtitle = 'Add a photo and confirm your details.',
  });

  final String submitLabel;
  final Future<bool> Function() onSubmit;
  final bool showHeader;
  final String headerTitle;
  final String headerSubtitle;

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
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
      return const Center(child: CircularProgressIndicator());
    }

    final timezoneItems = {
      ...TimezoneOptions.values,
      if (!TimezoneOptions.values.contains(form.timezone)) form.timezone,
    }.toList()
      ..sort();

    final languageCode = LanguageOptions.labels.containsKey(form.language)
        ? form.language
        : 'en';

    final avatarImage = notifier.avatarImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader) ...[
          Text(widget.headerTitle, style: theme.textTheme.headlineLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.headerSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (form.error != null) ...[
          ErrorBanner(message: form.error!, onDismiss: notifier.clearError),
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
              backgroundImage: avatarImage,
              child: avatarImage == null
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
          child: Text('Tap to change photo', style: theme.textTheme.bodySmall),
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
          key: ValueKey('timezone-${form.timezone}'),
          initialValue: form.timezone,
          decoration: const InputDecoration(labelText: 'Timezone'),
          items: timezoneItems
              .map((tz) => DropdownMenuItem(value: tz, child: Text(tz)))
              .toList(),
          onChanged: form.isLoading
              ? null
              : (value) {
                  if (value != null) notifier.setTimezone(value);
                },
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          key: ValueKey('language-$languageCode'),
          initialValue: languageCode,
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
          label: widget.submitLabel,
          isLoading: form.isLoading,
          onPressed: () async {
            final success = await widget.onSubmit();
            if (!success && mounted) {
              setState(() {});
            }
          },
        ),
      ],
    );
  }
}
