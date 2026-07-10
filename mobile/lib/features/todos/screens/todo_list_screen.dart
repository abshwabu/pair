import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pair/core/app_routes.dart';
import 'package:pair/core/theme/app_theme.dart';
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
      appBar: AppBar(title: const Text('Todos')),
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
    final open = groupOpenTodos(todos);
    final done = groupDoneTodos(todos);

    if (open.isEmpty && done.isEmpty) {
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
                      final error = await notifier.toggleDone(open[i].id);
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
            child: Text('Done', style: theme.textTheme.titleMedium),
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
                      final error = await notifier.toggleDone(done[i].id);
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
}
