import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_response.dart';
import 'package:pair/features/todos/models/todo_model.dart';
import 'package:pair/features/todos/services/todo_service.dart';

class TodosState {
  const TodosState({
    this.todos = const [],
    this.filter = TodoFilter.all,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.hasLoaded = false,
  });

  final List<TodoModel> todos;
  final TodoFilter filter;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final bool hasLoaded;

  TodosState copyWith({
    List<TodoModel>? todos,
    TodoFilter? filter,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    bool? hasLoaded,
    bool clearError = false,
  }) {
    return TodosState(
      todos: todos ?? this.todos,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : error ?? this.error,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

class TodosNotifier extends StateNotifier<TodosState> {
  TodosNotifier(this._ref, this._podId) : super(const TodosState()) {
    load();
  }

  final Ref _ref;
  final String _podId;

  Future<void> load() async {
    if (!state.hasLoaded) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(isRefreshing: true, clearError: true);
    }

    try {
      final todos = await _ref.read(todoServiceProvider).listTodos(_podId);
      state = state.copyWith(
        todos: todos,
        isLoading: false,
        isRefreshing: false,
        hasLoaded: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: 'Unable to load todos.',
      );
    }
  }

  void setFilter(TodoFilter filter) {
    state = state.copyWith(filter: filter);
  }

  List<TodoModel> filteredTodos({
    required String currentUserId,
    required String? partnerUserId,
  }) {
    return _applyFilter(
      state.todos,
      filter: state.filter,
      currentUserId: currentUserId,
      partnerUserId: partnerUserId,
    );
  }

  List<TodoModel> openTodos({
    required String currentUserId,
    int? limit,
  }) {
    final open = state.todos
        .where((todo) => todo.isActive && !todo.isDoneBy(currentUserId))
        .toList()
      ..sort(_compareByDueDate);
    if (limit != null && open.length > limit) {
      return open.take(limit).toList();
    }
    return open;
  }

  TodoModel? todoById(String todoId) {
    for (final todo in state.todos) {
      if (todo.id == todoId) return todo;
    }
    return null;
  }

  Future<String?> toggleMyCompletion(
    String todoId, {
    required String currentUserId,
  }) async {
    final index = state.todos.indexWhere((todo) => todo.id == todoId);
    if (index == -1) return 'Todo not found.';

    final original = state.todos[index];
    if (!original.isActive) {
      return 'You can only check off active todos.';
    }

    final nextDone = !original.isDoneBy(currentUserId);
    final optimistic = original.copyWith(
      myCompleted: nextDone,
      completions: _toggleCompletionForUser(
        original.completions,
        userId: currentUserId,
        completed: nextDone,
      ),
    );
    final updated = [...state.todos];
    updated[index] = optimistic;
    state = state.copyWith(todos: updated);

    try {
      final result = await _ref.read(todoServiceProvider).updateTodo(
            podId: _podId,
            todoId: todoId,
            myCompleted: nextDone,
          );
      updated[index] = result;
      state = state.copyWith(todos: updated);
      return null;
    } on ApiException catch (e) {
      updated[index] = original;
      state = state.copyWith(todos: updated);
      return e.message;
    } catch (_) {
      updated[index] = original;
      state = state.copyWith(todos: updated);
      return 'Unable to update todo.';
    }
  }

  Future<String?> createTodo({
    required String title,
    String? notes,
    DateTime? dueDate,
    String? assignedTo,
    TodoRecurrence? recurrence,
  }) async {
    try {
      final created = await _ref.read(todoServiceProvider).createTodo(
            podId: _podId,
            title: title,
            notes: notes,
            dueDate: dueDate,
            assignedTo: assignedTo,
            recurrence: recurrence,
          );
      state = state.copyWith(todos: [...state.todos, created]);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unable to propose todo.';
    }
  }

  Future<String?> updateTodo({
    required String todoId,
    required String title,
    String? notes,
    DateTime? dueDate,
    String? assignedTo,
    TodoRecurrence? recurrence,
    bool clearNotes = false,
    bool clearDueDate = false,
    bool clearAssignedTo = false,
    bool clearRecurrence = false,
  }) async {
    try {
      final updated = await _ref.read(todoServiceProvider).updateTodo(
            podId: _podId,
            todoId: todoId,
            title: title,
            notes: notes,
            dueDate: dueDate,
            assignedTo: assignedTo,
            recurrence: recurrence,
            clearNotes: clearNotes,
            clearDueDate: clearDueDate,
            clearAssignedTo: clearAssignedTo,
            clearRecurrence: clearRecurrence,
          );

      final todos = [
        for (final todo in state.todos)
          if (todo.id == todoId) updated else todo,
      ];
      state = state.copyWith(todos: todos);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unable to update todo.';
    }
  }

  Future<String?> requestDeletion(String todoId) async {
    try {
      final result = await _ref.read(todoServiceProvider).deleteTodo(
            podId: _podId,
            todoId: todoId,
          );
      if (result == null) {
        state = state.copyWith(
          todos: state.todos.where((todo) => todo.id != todoId).toList(),
        );
        return null;
      }
      final todos = [
        for (final todo in state.todos)
          if (todo.id == todoId) result else todo,
      ];
      state = state.copyWith(todos: todos);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unable to request deletion.';
    }
  }

  Future<String?> approveTodo(String todoId) async {
    try {
      final result = await _ref.read(todoServiceProvider).approveTodo(
            podId: _podId,
            todoId: todoId,
          );
      if (result == null) {
        state = state.copyWith(
          todos: state.todos.where((todo) => todo.id != todoId).toList(),
        );
        return null;
      }
      final todos = [
        for (final todo in state.todos)
          if (todo.id == todoId) result else todo,
      ];
      state = state.copyWith(todos: todos);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unable to approve todo.';
    }
  }

  Future<String?> rejectTodo(String todoId) async {
    try {
      final result = await _ref.read(todoServiceProvider).rejectTodo(
            podId: _podId,
            todoId: todoId,
          );
      if (result == null) {
        state = state.copyWith(
          todos: state.todos.where((todo) => todo.id != todoId).toList(),
        );
        return null;
      }
      final todos = [
        for (final todo in state.todos)
          if (todo.id == todoId) result else todo,
      ];
      state = state.copyWith(todos: todos);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unable to reject todo.';
    }
  }

  static List<TodoModel> _applyFilter(
    List<TodoModel> todos, {
    required TodoFilter filter,
    required String currentUserId,
    required String? partnerUserId,
  }) {
    switch (filter) {
      case TodoFilter.all:
        return todos;
      case TodoFilter.mine:
        return todos
            .where((todo) => todo.assignedTo == currentUserId)
            .toList();
      case TodoFilter.partners:
        return todos
            .where((todo) => todo.assignedTo == partnerUserId)
            .toList();
      case TodoFilter.shared:
        return todos.where((todo) => todo.assignedTo == null).toList();
      case TodoFilter.needsAction:
        return todos.where((todo) {
          if (todo.isPending && todo.createdBy != currentUserId) return true;
          if (todo.isPendingDeletion &&
              todo.deletionRequestedBy != currentUserId) {
            return true;
          }
          return false;
        }).toList();
    }
  }

  static int _compareByDueDate(TodoModel a, TodoModel b) {
    if (a.dueDate == null && b.dueDate == null) return 0;
    if (a.dueDate == null) return 1;
    if (b.dueDate == null) return -1;
    return a.dueDate!.compareTo(b.dueDate!);
  }

  static List<TodoCompletionModel> _toggleCompletionForUser(
    List<TodoCompletionModel> completions, {
    required String userId,
    required bool completed,
  }) {
    if (!completed) {
      return completions
          .where((completion) => completion.userId != userId)
          .toList();
    }

    if (completions.any((completion) => completion.userId == userId)) {
      return completions;
    }

    return [
      ...completions,
      TodoCompletionModel(userId: userId, completedAt: DateTime.now()),
    ];
  }
}

final todosProvider =
    StateNotifierProvider.family<TodosNotifier, TodosState, String>(
  (ref, podId) => TodosNotifier(ref, podId),
);

List<TodoModel> groupOpenTodos(
  List<TodoModel> todos, {
  required String currentUserId,
}) {
  final open = todos
      .where((todo) => todo.isActive && !todo.isDoneBy(currentUserId))
      .toList()
    ..sort(TodosNotifier._compareByDueDate);
  return open;
}

List<TodoModel> groupDoneTodos(
  List<TodoModel> todos, {
  required String currentUserId,
}) {
  final done = todos
      .where((todo) => todo.isActive && todo.isDoneBy(currentUserId))
      .toList()
    ..sort(TodosNotifier._compareByDueDate);
  return done;
}

List<TodoModel> groupPendingApprovalTodos({
  required List<TodoModel> todos,
  required String currentUserId,
}) {
  return todos.where((todo) {
    if (todo.isPending && todo.createdBy != currentUserId) return true;
    if (todo.isPendingDeletion && todo.deletionRequestedBy != currentUserId) {
      return true;
    }
    return false;
  }).toList();
}

List<TodoModel> groupWaitingOnPartnerTodos({
  required List<TodoModel> todos,
  required String currentUserId,
}) {
  return todos.where((todo) {
    if (todo.isPending && todo.createdBy == currentUserId) return true;
    if (todo.isPendingDeletion && todo.deletionRequestedBy == currentUserId) {
      return true;
    }
    return false;
  }).toList();
}

String formatRecurrenceLabel(TodoRecurrence recurrence) {
  return switch (recurrence) {
    TodoRecurrence.daily => 'Daily',
    TodoRecurrence.weekly => 'Weekly',
    TodoRecurrence.monthly => 'Monthly',
    TodoRecurrence.yearly => 'Yearly',
  };
}

String formatTodoDueDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

TodoAssigneeOption assigneeOptionForTodo({
  required TodoModel todo,
  required String currentUserId,
}) {
  if (todo.assignedTo == null) return TodoAssigneeOption.shared;
  if (todo.assignedTo == currentUserId) return TodoAssigneeOption.me;
  return TodoAssigneeOption.partner;
}

String? assignedToForOption({
  required TodoAssigneeOption option,
  required String currentUserId,
  required String? partnerUserId,
}) {
  switch (option) {
    case TodoAssigneeOption.me:
      return currentUserId;
    case TodoAssigneeOption.partner:
      return partnerUserId;
    case TodoAssigneeOption.shared:
      return null;
  }
}
