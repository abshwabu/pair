import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/features/matching/providers/finding_match_provider.dart';
import 'package:pair/features/pods/widgets/partner_avatar.dart';

class PodHomeScreen extends ConsumerWidget {
  const PodHomeScreen({super.key, required this.podId});

  final String podId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final podAsync = ref.watch(podDetailProvider(podId));
    final userAsync = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your pod'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.podSettingsPath(podId)),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Pod settings',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.chatPath(podId)),
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Chat'),
      ),
      body: podAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Unable to load your pod.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (pod) {
          final currentUserId = userAsync.value?.id;
          final partner = currentUserId != null
              ? pod.activePartnerFor(currentUserId)
              : null;
          final streakCount = pod.streak?.currentStreak ?? 0;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        if (partner != null)
                          PartnerAvatar(
                            name: partner.user.name,
                            avatarUrl: partner.user.avatarUrl,
                          )
                        else
                          CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.primaryContainer,
                            child: Icon(
                              Icons.person_outline,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                partner?.user.name ?? 'Your partner',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                partner?.goal.title ?? pod.goalCategory,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StreakBadge(
                          currentStreak: streakCount,
                          onTap: () =>
                              context.push(AppRoutes.streakDetailPath(podId)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Open todos', style: theme.textTheme.titleMedium),
                    TextButton(
                      onPressed: () =>
                          context.push(AppRoutes.todoListPath(podId)),
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        Icon(
                          Icons.checklist_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Shared todos coming soon',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
