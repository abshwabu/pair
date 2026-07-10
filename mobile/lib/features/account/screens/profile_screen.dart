import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/features/account/providers/profile_provider.dart';
import 'package:pair/features/onboarding/data/onboarding_options.dart';
import 'package:pair/features/pods/widgets/partner_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.profileEdit),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit profile',
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Unable to load profile.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (user) {
          final languageLabel =
              LanguageOptions.labels[user.language ?? 'en'] ?? user.language;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Center(
                child: PartnerAvatar(
                  name: user.name,
                  avatarUrl: user.avatarUrl,
                  radius: 40,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(user.name, style: theme.textTheme.headlineMedium),
              ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: Text(
                  user.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.schedule_outlined),
                      title: const Text('Timezone'),
                      subtitle: Text(user.timezone ?? 'UTC'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.language_outlined),
                      title: const Text('Language'),
                      subtitle: Text(languageLabel ?? 'English'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Account', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications_outlined),
                      title: const Text('Notification settings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRoutes.notificationSettings),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.block_outlined),
                      title: const Text('Blocked users'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRoutes.blockedUsers),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.manage_accounts_outlined),
                      title: const Text('Account settings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRoutes.accountSettings),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
