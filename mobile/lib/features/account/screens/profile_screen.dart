import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/auth_state.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/main_bottom_nav.dart';
import 'package:pair/core/widgets/pair_app_bar.dart';
import 'package:pair/features/account/providers/profile_provider.dart';
import 'package:pair/features/auth/services/auth_service.dart';
import 'package:pair/features/onboarding/data/onboarding_options.dart';
import 'package:pair/features/pods/widgets/partner_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to access your pod.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(authServiceProvider).clearToken();
    if (!context.mounted) return;
    notifyAuthChanged(ref);
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const PairAppBar(title: 'Profile', showBack: false),
      bottomNavigationBar: const MainBottomNav(currentTab: MainTab.profile),
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
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push(AppRoutes.profileEdit),
                    customBorder: const CircleBorder(),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        PartnerAvatar(
                          name: user.name,
                          avatarUrl: user.avatarUrl,
                          radius: 44,
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: theme.colorScheme.primary,
                            child: Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton.icon(
                  onPressed: () => context.push(AppRoutes.profileEdit),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit name & photo'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications_outlined),
                      title: const Text('Notification settings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          context.push(AppRoutes.notificationSettings),
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
                      subtitle: const Text('Password, delete account'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRoutes.accountSettings),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton.icon(
                onPressed: () => _logout(context, ref),
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
