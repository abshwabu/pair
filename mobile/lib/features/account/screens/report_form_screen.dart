import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/network/api_response.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/pair_app_bar.dart';
import 'package:pair/core/widgets/primary_button.dart';
import 'package:pair/features/account/services/report_service.dart';

class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({
    super.key,
    required this.reportedUserId,
    this.podId,
  });

  final String reportedUserId;
  final String? podId;

  @override
  ConsumerState<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends ConsumerState<ReportFormScreen> {
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'Please describe the issue.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await ref.read(reportServiceProvider).submitReport(
            reportedUserId: widget.reportedUserId,
            podId: widget.podId,
            reason: reason,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted. Thank you.')),
      );
      context.pop();
    } on ApiException catch (e) {
      setState(() {
        _isSubmitting = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _isSubmitting = false;
        _error = 'Unable to submit report.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PairAppBar(
        title: 'Report',
        fallbackRoute: widget.podId != null
            ? AppRoutes.podSettingsPath(widget.podId!)
            : AppRoutes.profile,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tell us what happened',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Reports are reviewed by our team. Include enough detail to help us understand the issue.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _reasonController,
                minLines: 4,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Describe the inappropriate behavior…',
                  alignLabelWithHint: true,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const Spacer(),
              PrimaryButton(
                label: 'Submit report',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
