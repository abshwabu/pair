import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/primary_button.dart';
import 'package:pair/features/todos/models/todo_model.dart';
import 'package:pair/features/todos/providers/todos_provider.dart';

Future<bool?> showTodoFormSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String podId,
  required String currentUserId,
  required String? partnerUserId,
  TodoModel? existing,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => TodoFormSheet(
      podId: podId,
      currentUserId: currentUserId,
      partnerUserId: partnerUserId,
      existing: existing,
    ),
  );
}

class TodoFormSheet extends ConsumerStatefulWidget {
  const TodoFormSheet({
    super.key,
    required this.podId,
    required this.currentUserId,
    required this.partnerUserId,
    this.existing,
  });

  final String podId;
  final String currentUserId;
  final String? partnerUserId;
  final TodoModel? existing;

  @override
  ConsumerState<TodoFormSheet> createState() => _TodoFormSheetState();
}

class _TodoFormSheetState extends ConsumerState<TodoFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  DateTime? _dueDate;
  late TodoAssigneeOption _assignee;
  bool _isSubmitting = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  bool get _needsPartnerApproval => _assignee != TodoAssigneeOption.me;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _dueDate = existing?.dueDate;
    _assignee = existing != null
        ? assigneeOptionForTodo(
            todo: existing,
            currentUserId: widget.currentUserId,
          )
        : TodoAssigneeOption.shared;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Title is required.');
      return;
    }

    if (_assignee == TodoAssigneeOption.partner &&
        widget.partnerUserId == null) {
      setState(() => _error = 'Partner is unavailable.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final assignedTo = assignedToForOption(
      option: _assignee,
      currentUserId: widget.currentUserId,
      partnerUserId: widget.partnerUserId,
    );

    final notes = _notesController.text.trim();
    final notifier = ref.read(todosProvider(widget.podId).notifier);

    final String? error;
    if (_isEditing) {
      error = await notifier.updateTodo(
        todoId: widget.existing!.id,
        title: title,
        notes: notes.isEmpty ? null : notes,
        dueDate: _dueDate,
        assignedTo: assignedTo,
        clearNotes: notes.isEmpty,
        clearDueDate: _dueDate == null,
        clearAssignedTo: assignedTo == null,
      );
    } else {
      error = await notifier.createTodo(
        title: title,
        notes: notes.isEmpty ? null : notes,
        dueDate: _dueDate,
        assignedTo: assignedTo,
      );
    }

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isSubmitting = false;
        _error = error;
      });
      return;
    }

    if (!mounted) return;

    if (!_isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todo sent — waiting for your partner to approve.'),
        ),
      );
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          Text(
            _isEditing
                ? 'Edit todo'
                : _needsPartnerApproval
                    ? 'Propose todo'
                    : 'Add todo',
            style: theme.textTheme.headlineSmall,
          ),
          if (!_isEditing && _needsPartnerApproval) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Your partner must approve shared and partner todos before they appear on the pod list.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes'),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _isSubmitting ? null : _pickDueDate,
            icon: const Icon(Icons.event_outlined),
            label: Text(
              _dueDate == null
                  ? 'Set due date'
                  : 'Due ${formatTodoDueDate(_dueDate!)}',
            ),
          ),
          if (_dueDate != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _isSubmitting ? null : () => setState(() => _dueDate = null),
                child: const Text('Clear due date'),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text('Assignee', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<TodoAssigneeOption>(
            segments: const [
              ButtonSegment(value: TodoAssigneeOption.me, label: Text('Me')),
              ButtonSegment(
                value: TodoAssigneeOption.partner,
                label: Text('Partner'),
              ),
              ButtonSegment(
                value: TodoAssigneeOption.shared,
                label: Text('Shared'),
              ),
            ],
            selected: {_assignee},
            onSelectionChanged: _isSubmitting
                ? null
                : (selection) => setState(() => _assignee = selection.first),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: _isEditing
                ? 'Save changes'
                : _needsPartnerApproval
                    ? 'Send to partner'
                    : 'Add todo',
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
