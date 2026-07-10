import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/primary_button.dart';
import 'package:pair/features/checkins/providers/streak_provider.dart';

Future<bool?> showCheckInModal({
  required BuildContext context,
  required WidgetRef ref,
  required String podId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => CheckInModal(podId: podId),
  );
}

class CheckInModal extends ConsumerStatefulWidget {
  const CheckInModal({super.key, required this.podId});

  final String podId;

  @override
  ConsumerState<CheckInModal> createState() => _CheckInModalState();
}

class _CheckInModalState extends ConsumerState<CheckInModal> {
  final _noteController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error = await ref
        .read(streakProvider(widget.podId).notifier)
        .checkIn(note: _noteController.text);

    if (!mounted) return;

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final streakState = ref.watch(streakProvider(widget.podId));
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Daily check-in', style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Optional: add a short note about your progress today.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _noteController,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'What did you accomplish today?',
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
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Confirm check-in',
            isLoading: streakState.isCheckingIn,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
