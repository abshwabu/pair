import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/pair_app_bar.dart';
import 'package:pair/core/widgets/error_banner.dart';
import 'package:pair/features/account/providers/blocked_users_provider.dart';
import 'package:pair/features/pods/widgets/partner_avatar.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(blockedUsersProvider);
    final notifier = ref.read(blockedUsersProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const PairAppBar(
        title: 'Blocked users',
        fallbackRoute: AppRoutes.profile,
      ),
      body: state.isLoading && !state.hasLoaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                if (state.error != null) ...[
                  ErrorBanner(message: state.error!),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (state.blocks.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'You have not blocked anyone.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < state.blocks.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          ListTile(
                            leading: PartnerAvatar(
                              name: state.blocks[i].blockedUserName,
                              avatarUrl: state.blocks[i].blockedUserAvatarUrl,
                              radius: 20,
                            ),
                            title: Text(state.blocks[i].blockedUserName),
                            trailing: state.unblockingId == state.blocks[i].id
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : TextButton(
                                    onPressed: () =>
                                        notifier.unblock(state.blocks[i].id),
                                    child: const Text('Unblock'),
                                  ),
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
