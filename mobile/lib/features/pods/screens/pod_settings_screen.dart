import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/network/api_response.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/error_banner.dart';
import 'package:pair/core/widgets/pair_app_bar.dart';
import 'package:pair/features/matching/providers/finding_match_provider.dart';
import 'package:pair/features/account/services/block_service.dart';
import 'package:pair/features/pods/services/pod_service.dart';

class PodSettingsScreen extends ConsumerStatefulWidget {
  const PodSettingsScreen({super.key, required this.podId});

  final String podId;

  @override
  ConsumerState<PodSettingsScreen> createState() => _PodSettingsScreenState();
}

class _PodSettingsScreenState extends ConsumerState<PodSettingsScreen> {
  bool _isLeaving = false;
  bool _isBlocking = false;
  String? _error;

  Future<void> _confirmLeave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave pod?'),
        content: const Text(
          'You will leave this accountability pod and can start a new match.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave pod'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isLeaving = true;
      _error = null;
    });

    try {
      await ref.read(podServiceProvider).leavePod(widget.podId);
      if (!mounted) return;
      context.go(AppRoutes.goalCategory);
    } on ApiException catch (e) {
      setState(() {
        _isLeaving = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _isLeaving = false;
        _error = 'Unable to leave pod. Please try again.';
      });
    }
  }

  Future<void> _confirmBlock() async {
    final pod = await ref.read(podServiceProvider).getPod(widget.podId);
    final currentUserId = await ref.read(currentUserProvider.future);
    final partner = pod.activePartnerFor(currentUserId.id);

    if (partner == null) {
      setState(() => _error = 'Partner not found.');
      return;
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block partner?'),
        content: Text(
          'Block ${partner.user.name}? You will leave this pod and will not be matched with them again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isBlocking = true;
      _error = null;
    });

    try {
      await ref
          .read(blockServiceProvider)
          .blockUser(partner.user.id);
      if (!mounted) return;
      context.go(AppRoutes.goalCategory);
    } on ApiException catch (e) {
      setState(() {
        _isBlocking = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _isBlocking = false;
        _error = 'Unable to block user. Please try again.';
      });
    }
  }

  Future<void> _openReport() async {
    final pod = await ref.read(podServiceProvider).getPod(widget.podId);
    final currentUserId = await ref.read(currentUserProvider.future);
    final partner = pod.activePartnerFor(currentUserId.id);

    if (partner == null) {
      if (!mounted) return;
      setState(() => _error = 'Partner not found.');
      return;
    }

    if (!mounted) return;
    await context.push(
      AppRoutes.reportFormPath(
        podId: widget.podId,
        reportedUserId: partner.user.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBusy = _isLeaving || _isBlocking;

    return Scaffold(
      appBar: PairAppBar(
        title: 'Pod settings',
        fallbackRoute: AppRoutes.podHomePath(widget.podId),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (_error != null) ...[
              ErrorBanner(
                message: _error!,
                onDismiss: () => setState(() => _error = null),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              'Pod options',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.exit_to_app_outlined),
                    title: const Text('Leave pod'),
                    subtitle: const Text('Start a new match'),
                    enabled: !isBusy,
                    onTap: _isLeaving ? null : _confirmLeave,
                    trailing: _isLeaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.flag_outlined),
                    title: const Text('Report'),
                    subtitle: const Text('Report inappropriate behavior'),
                    enabled: !isBusy,
                    onTap: isBusy ? null : _openReport,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.block_outlined),
                    title: const Text('Block'),
                    subtitle: const Text('Block your partner'),
                    enabled: !isBusy,
                    onTap: _isBlocking ? null : _confirmBlock,
                    trailing: _isBlocking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined),
                    title: const Text('Pod notifications'),
                    subtitle: const Text('Coming soon'),
                    value: false,
                    onChanged: null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
