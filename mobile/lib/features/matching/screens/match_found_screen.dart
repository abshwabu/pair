import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/primary_button.dart';
import 'package:pair/features/matching/providers/finding_match_provider.dart';
import 'package:pair/features/pods/widgets/partner_avatar.dart';

class MatchFoundScreen extends ConsumerWidget {
  const MatchFoundScreen({super.key, required this.podId});

  final String podId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final podAsync = ref.watch(podDetailProvider(podId));
    final userAsync = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: podAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Unable to load your match. Please try again.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (pod) {
            final currentUserId = userAsync.asData?.value.id;
            final partner = currentUserId != null
                ? pod.activePartnerFor(currentUserId)
                : pod.members
                    .where((member) => member.isActive)
                    .map((member) => member)
                    .firstOrNull;

            if (partner == null) {
              return Center(
                child: Text(
                  'Match details are unavailable.',
                  style: theme.textTheme.bodyLarge,
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  const Spacer(),
                  Icon(
                    Icons.celebration_outlined,
                    size: 48,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'You matched!',
                    style: theme.textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Meet your new accountability partner.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          PartnerAvatar(
                            name: partner.user.name,
                            avatarUrl: partner.user.avatarUrl,
                            radius: 40,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            partner.user.name,
                            style: theme.textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            partner.goal.title,
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            partner.goal.targetDescription,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: "Let's start",
                    onPressed: () => context.go(AppRoutes.podHomePath(podId)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
