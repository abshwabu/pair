import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/theme/app_theme.dart';
import 'package:pair/core/widgets/pair_app_bar.dart';
import 'package:pair/core/widgets/primary_button.dart';
import 'package:pair/features/matching/providers/finding_match_provider.dart';
import 'package:pair/features/pods/models/pod_model.dart';
import 'package:pair/features/todos/models/todo_model.dart';
import 'package:pair/features/todos/providers/todos_provider.dart';
import 'package:pair/features/todos/widgets/todo_form_sheet.dart';
import 'package:pair/features/todos/widgets/todo_row.dart';

class TodoListScreen extends ConsumerWidget {
  const TodoListScreen({super.key, required this.podId});

  final String podId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosState = ref.watch(todosProvider(podId));
    final notifier = ref.read(todosProvider(podId).notifier);
    final userAsync = ref.watch(currentUserProvider);
    final podAsync = ref.watch(podDetailProvider(podId));
    final theme = Theme.of(context);

    final currentUserId = userAsync.asData?.value.id;
    final partner = podAsync.asData?.value.activePartnerFor(
      currentUserId ?? '',
    );

    return Scaffold(
      appBar: PairAppBar(
        title: 'Todos',
        fallbackRoute: AppRoutes.podHomePath(podId),
      ),
      floatingActionButton: currentUserId == null
          ? null
          : FloatingActionButton(
              onPressed: () => showTodoFormSheet(
                context: context,
                ref: ref,
                podId: podId,
                currentUserId: currentUserId,
                partnerUserId: partner?.user.id,
              ),
              child: const Icon(Icons.add),
            ),
      body: currentUserId == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FilterChips(
                  selected: todosState.filter,
                  onSelected: notifier.setFilter,
                ),
                Expanded(
                  child: todosState.isLoading && !todosState.hasLoaded
                      ? const Center(child: CircularProgressIndicator())
                      : todosState.error != null && !todosState.hasLoaded
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Text(
                                  todosState.error!,
                                  style: theme.textTheme.bodyLarge,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: notifier.load,
                              child: _TodoListBody(
                                podId: podId,
                                currentUserId: currentUserId,
                                partner: partner,
                                todos: notifier.filteredTodos(
                                  currentUserId: currentUserId,
                                  partnerUserId: partner?.user.id,
                                ),
                              ),
                            ),
                ),
              ],
            ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.onSelected,
  });

  final TodoFilter selected;
  final ValueChanged<TodoFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          _chip('All', TodoFilter.all),
          const SizedBox(width: AppSpacing.xs),
          _chip('Needs action', TodoFilter.needsAction),
          const SizedBox(width: AppSpacing.xs),
          _chip('Mine', TodoFilter.mine),
          const SizedBox(width: AppSpacing.xs),
          _chip("Partner's", TodoFilter.partners),
          const SizedBox(width: AppSpacing.xs),
          _chip('Shared', TodoFilter.shared),
        ],
      ),
    );
  }

  Widget _chip(String label, TodoFilter filter) {
    return FilterChip(
      label: Text(label),
      selected: selected == filter,
      onSelected: (_) => onSelected(filter),
    );
  }
}

class _TodoListBody extends ConsumerWidget {
  const _TodoListBody({
    required this.podId,
    required this.currentUserId,
    required this.partner,
    required this.todos,
  });

  final String podId;
  final String currentUserId;
  final PodMemberModel? partner;
  final List<TodoModel> todos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(todosProvider(podId).notifier);

    final needsApproval = groupPendingApprovalTodos(
      todos: todos,
      currentUserId: currentUserId,
    );
    final waitingOnPartner = groupWaitingOnPartnerTodos(
      todos: todos,
      currentUserId: currentUserId,
    );
    final open = groupOpenTodos(todos, currentUserId: currentUserId);
    final done = groupDoneTodos(todos, currentUserId: currentUserId);

    if (needsApproval.isEmpty &&
        waitingOnPartner.isEmpty &&
        open.isEmpty &&
        done.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Icon(
            Icons.checklist_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No todos yet',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        if (needsApproval.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Text('Needs your approval', style: theme.textTheme.titleMedium),
          ),
          ...needsApproval.map(
            (todo) => Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: _ApprovalCard(
                todo: todo,
                onApprove: () => _handleApprove(context, notifier, todo.id),
                onReject: () => _handleReject(context, notifier, todo.id),
              ),
            ),
          ),
        ],
        if (waitingOnPartner.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Text('Waiting on partner', style: theme.textTheme.titleMedium),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                for (var i = 0; i < waitingOnPartner.length; i++) ...[
                  ListTile(
                    title: Text(waitingOnPartner[i].title),
                    subtitle: Text(
                      waitingOnPartner[i].isPending
                          ? 'Waiting for partner to approve new todo'
                          : 'Waiting for partner to approve removal',
                    ),
                  ),
                  if (i < waitingOnPartner.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (open.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Text('Open', style: theme.textTheme.titleMedium),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < open.length; i++) ...[
                  TodoRow(
                    todo: open[i],
                    currentUserId: currentUserId,
                    partner: partner,
                    onToggle: (_) async {
                      final error =
                          await notifier.toggleMyCompletion(
                            open[i].id,
                            currentUserId: currentUserId,
                          );
                      if (error != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error)),
                        );
                      }
                    },
                    onTap: () => context.push(
                      AppRoutes.todoDetailPath(podId, open[i].id),
                    ),
                  ),
                  if (i < open.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
        if (done.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Text('Done by you', style: theme.textTheme.titleMedium),
          ),
          Card(
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < done.length; i++) ...[
                  TodoRow(
                    todo: done[i],
                    currentUserId: currentUserId,
                    partner: partner,
                    onToggle: (_) async {
                      final error =
                          await notifier.toggleMyCompletion(
                            done[i].id,
                            currentUserId: currentUserId,
                          );
                      if (error != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error)),
                        );
                      }
                    },
                    onTap: () => context.push(
                      AppRoutes.todoDetailPath(podId, done[i].id),
                    ),
                  ),
                  if (i < done.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleApprove(
    BuildContext context,
    TodosNotifier notifier,
    String todoId,
  ) async {
    final error = await notifier.approveTodo(todoId);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<void> _handleReject(
    BuildContext context,
    TodosNotifier notifier,
    String todoId,
  ) async {
    final error = await notifier.rejectTodo(todoId);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.todo,
    required this.onApprove,
    required this.onReject,
  });

  final TodoModel todo;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDeletion = todo.isPendingDeletion;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isDeletion ? 'Remove todo?' : 'Approve todo?',
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(todo.title, style: theme.textTheme.titleMedium),
            if (todo.notes != null && todo.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(todo.notes!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    child: Text(isDeletion ? 'Keep' : 'Decline'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PrimaryButton(
                    label: isDeletion ? 'Remove' : 'Approve',
                    onPressed: onApprove,
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
