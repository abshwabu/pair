import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/pair_app_bar.dart';
import 'package:pair/features/account/providers/notification_preferences_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPreferencesProvider);
    final notifier = ref.read(notificationPreferencesProvider.notifier);
    final theme = Theme.of(context);

    if (prefs.isEmpty) {
      return Scaffold(
        appBar: const PairAppBar(
          title: 'Notification settings',
          fallbackRoute: AppRoutes.profile,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const PairAppBar(
        title: 'Notification settings',
        fallbackRoute: AppRoutes.profile,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Choose which notifications appear on this device. '
            'Your partner and pod activity are still tracked in the app.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < NotificationTypes.all.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined),
                    title: Text(NotificationTypes.label(NotificationTypes.all[i])),
                    subtitle: Text(
                      NotificationTypes.description(NotificationTypes.all[i]),
                    ),
                    value: prefs[NotificationTypes.all[i]] ?? true,
                    onChanged: (enabled) =>
                        notifier.setEnabled(NotificationTypes.all[i], enabled),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
