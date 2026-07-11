class TodoCompletionModel {
  const TodoCompletionModel({
    required this.userId,
    this.completedAt,
  });

  final String userId;
  final DateTime? completedAt;

  factory TodoCompletionModel.fromJson(Map<String, dynamic> json) {
    return TodoCompletionModel(
      userId: json['user_id'] as String,
      completedAt: _parseDateTime(json['completed_at']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }
}

enum TodoStatus { pending, active, pendingDeletion }

class TodoModel {
  const TodoModel({
    required this.id,
    required this.podId,
    required this.status,
    required this.createdBy,
    required this.title,
    this.deletionRequestedBy,
    this.assignedTo,
    this.notes,
    this.dueDate,
    this.completions = const [],
    this.myCompleted = false,
  });

  final String id;
  final String podId;
  final TodoStatus status;
  final String createdBy;
  final String? deletionRequestedBy;
  final String title;
  final String? assignedTo;
  final String? notes;
  final DateTime? dueDate;
  final List<TodoCompletionModel> completions;
  final bool myCompleted;

  bool get isActive => status == TodoStatus.active;
  bool get isPending => status == TodoStatus.pending;
  bool get isPendingDeletion => status == TodoStatus.pendingDeletion;

  bool isCompletedBy(String userId) {
    return completions.any((completion) => completion.userId == userId);
  }

  bool get isFullyCompleted {
    return completions.length >= 2;
  }

  TodoModel copyWith({
    String? id,
    String? podId,
    TodoStatus? status,
    String? createdBy,
    String? deletionRequestedBy,
    String? title,
    String? assignedTo,
    String? notes,
    DateTime? dueDate,
    List<TodoCompletionModel>? completions,
    bool? myCompleted,
    bool clearAssignedTo = false,
    bool clearNotes = false,
    bool clearDueDate = false,
    bool clearDeletionRequestedBy = false,
  }) {
    return TodoModel(
      id: id ?? this.id,
      podId: podId ?? this.podId,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      deletionRequestedBy: clearDeletionRequestedBy
          ? null
          : deletionRequestedBy ?? this.deletionRequestedBy,
      title: title ?? this.title,
      assignedTo: clearAssignedTo ? null : assignedTo ?? this.assignedTo,
      notes: clearNotes ? null : notes ?? this.notes,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      completions: completions ?? this.completions,
      myCompleted: myCompleted ?? this.myCompleted,
    );
  }

  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      id: json['id'] as String,
      podId: json['pod_id'] as String,
      status: _parseStatus(json['status'] as String? ?? 'active'),
      createdBy: json['created_by'] as String,
      deletionRequestedBy: json['deletion_requested_by'] as String?,
      title: json['title'] as String,
      assignedTo: json['assigned_to'] as String?,
      notes: json['notes'] as String?,
      dueDate: _parseDate(json['due_date']),
      completions: (json['completions'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TodoCompletionModel.fromJson)
          .toList(),
      myCompleted: json['my_completed'] as bool? ?? false,
    );
  }

  static TodoStatus _parseStatus(String value) {
    return switch (value) {
      'pending' => TodoStatus.pending,
      'pending_deletion' => TodoStatus.pendingDeletion,
      _ => TodoStatus.active,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }
}

enum TodoFilter { all, mine, partners, shared, needsAction }

enum TodoAssigneeOption { me, partner, shared }
