import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pair/core/network/api_client.dart';
import 'package:pair/features/todos/models/todo_model.dart';

class TodoService {
  TodoService(this._api);

  final ApiClient _api;

  Future<List<TodoModel>> listTodos(String podId) async {
    final response = await _api.get<List<dynamic>>(
      '/pods/$podId/todos',
      queryParameters: const {'sort_direction': 'asc'},
      fromJsonT: (json) => (json as List).toList(),
    );

    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(TodoModel.fromJson)
        .toList();
  }

  Future<TodoModel> createTodo({
    required String podId,
    required String title,
    String? notes,
    DateTime? dueDate,
    String? assignedTo,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/pods/$podId/todos',
      data: {
        'title': title,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (dueDate != null) 'due_date': _formatDate(dueDate),
        'assigned_to': assignedTo,
      },
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return TodoModel.fromJson(response.data!);
  }

  Future<TodoModel> updateTodo({
    required String podId,
    required String todoId,
    String? title,
    String? notes,
    DateTime? dueDate,
    String? assignedTo,
    bool? myCompleted,
    bool clearNotes = false,
    bool clearDueDate = false,
    bool clearAssignedTo = false,
  }) async {
    final data = <String, dynamic>{};

    if (title != null) data['title'] = title;
    if (notes != null) data['notes'] = notes;
    if (clearNotes) data['notes'] = null;
    if (dueDate != null) {
      data['due_date'] = _formatDate(dueDate);
    } else if (clearDueDate) {
      data['due_date'] = null;
    }
    if (assignedTo != null) {
      data['assigned_to'] = assignedTo;
    } else if (clearAssignedTo) {
      data['assigned_to'] = null;
    }
    if (myCompleted != null) data['my_completed'] = myCompleted;

    final response = await _api.patch<Map<String, dynamic>>(
      '/pods/$podId/todos/$todoId',
      data: data,
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return TodoModel.fromJson(response.data!);
  }

  /// Returns null when the todo was removed (cancelled proposal / approved deletion).
  Future<TodoModel?> deleteTodo({
    required String podId,
    required String todoId,
  }) async {
    final response = await _api.delete<Map<String, dynamic>>(
      '/pods/$podId/todos/$todoId',
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    final data = response.data;
    if (data == null || data.containsKey('message')) {
      return null;
    }
    return TodoModel.fromJson(data);
  }

  Future<TodoModel?> approveTodo({
    required String podId,
    required String todoId,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/pods/$podId/todos/$todoId/approve',
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    final data = response.data;
    if (data == null || data.containsKey('message')) {
      return null;
    }
    return TodoModel.fromJson(data);
  }

  Future<TodoModel?> rejectTodo({
    required String podId,
    required String todoId,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/pods/$podId/todos/$todoId/reject',
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    final data = response.data;
    if (data == null || data.containsKey('message')) {
      return null;
    }
    return TodoModel.fromJson(data);
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

final todoServiceProvider = Provider<TodoService>((ref) {
  return TodoService(ref.watch(apiClientProvider));
});
