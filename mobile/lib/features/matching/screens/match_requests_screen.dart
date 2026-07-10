import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/network/api_response.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/error_banner.dart';
import 'package:pair/core/widgets/pair_app_bar.dart';
import 'package:pair/core/widgets/primary_button.dart';
import 'package:pair/features/matching/models/partner_match_request_model.dart';
import 'package:pair/features/matching/providers/partner_match_request_provider.dart';
import 'package:pair/features/matching/services/matching_service.dart';
import 'package:pair/features/pods/widgets/partner_avatar.dart';

class MatchRequestsScreen extends ConsumerWidget {
  const MatchRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(incomingPartnerMatchRequestsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const PairAppBar(
        title: 'Match requests',
        fallbackRoute: AppRoutes.goalCategory,
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Unable to load match requests.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'No pending match requests.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              return _IncomingRequestCard(request: requests[index]);
            },
          );
        },
      ),
    );
  }
}

class _IncomingRequestCard extends ConsumerStatefulWidget {
  const _IncomingRequestCard({required this.request});

  final PartnerMatchRequestModel request;

  @override
  ConsumerState<_IncomingRequestCard> createState() =>
      _IncomingRequestCardState();
}

class _IncomingRequestCardState extends ConsumerState<_IncomingRequestCard> {
  bool _isAccepting = false;
  bool _isDeclining = false;
  String? _error;

  Future<void> _accept() async {
    setState(() {
      _isAccepting = true;
      _error = null;
    });

    try {
      final result = await ref
          .read(matchingServiceProvider)
          .acceptPartnerRequest(widget.request.id);
      ref.invalidate(incomingPartnerMatchRequestsProvider);
      if (!mounted) return;
      if (result.podId != null) {
        context.go(AppRoutes.matchFoundPath(result.podId!));
      }
    } on ApiException catch (e) {
      setState(() {
        _isAccepting = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _isAccepting = false;
        _error = 'Unable to accept request.';
      });
    }
  }

  Future<void> _decline() async {
    setState(() {
      _isDeclining = true;
      _error = null;
    });

    try {
      await ref
          .read(matchingServiceProvider)
          .declinePartnerRequest(widget.request.id);
      ref.invalidate(incomingPartnerMatchRequestsProvider);
      if (mounted) setState(() => _isDeclining = false);
    } on ApiException catch (e) {
      setState(() {
        _isDeclining = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _isDeclining = false;
        _error = 'Unable to decline request.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requester = widget.request.requester;
    final goal = widget.request.requesterGoal;
    final isBusy = _isAccepting || _isDeclining;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (requester != null)
              Row(
                children: [
                  PartnerAvatar(
                    name: requester.name,
                    avatarUrl: requester.avatarUrl,
                    radius: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      requester.name,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            if (goal != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(goal.title, style: theme.textTheme.titleSmall),
              if (goal.targetDescription.isNotEmpty)
                Text(
                  goal.targetDescription,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (_error != null) ...[
              ErrorBanner(message: _error!),
              const SizedBox(height: AppSpacing.sm),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isBusy ? null : _decline,
                    child: _isDeclining
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Decline'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PrimaryButton(
                    label: 'Accept',
                    isLoading: _isAccepting,
                    onPressed: isBusy ? null : _accept,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
