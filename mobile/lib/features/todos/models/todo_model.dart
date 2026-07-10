class TodoModel {
  const TodoModel({
    required this.id,
    required this.podId,
    required this.createdBy,
    required this.title,
    this.assignedTo,
    this.notes,
    this.dueDate,
    this.isDone = false,
    this.completedAt,
  });

  final String id;
  final String podId;
  final String createdBy;
  final String title;
  final String? assignedTo;
  final String? notes;
  final DateTime? dueDate;
  final bool isDone;
  final DateTime? completedAt;

  TodoModel copyWith({
    String? id,
    String? podId,
    String? createdBy,
    String? title,
    String? assignedTo,
    String? notes,
    DateTime? dueDate,
    bool? isDone,
    DateTime? completedAt,
    bool clearAssignedTo = false,
    bool clearNotes = false,
    bool clearDueDate = false,
    bool clearCompletedAt = false,
  }) {
    return TodoModel(
      id: id ?? this.id,
      podId: podId ?? this.podId,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      assignedTo: clearAssignedTo ? null : assignedTo ?? this.assignedTo,
      notes: clearNotes ? null : notes ?? this.notes,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      isDone: isDone ?? this.isDone,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
    );
  }

  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      id: json['id'] as String,
      podId: json['pod_id'] as String,
      createdBy: json['created_by'] as String,
      title: json['title'] as String,
      assignedTo: json['assigned_to'] as String?,
      notes: json['notes'] as String?,
      dueDate: _parseDate(json['due_date']),
      isDone: json['is_done'] as bool? ?? false,
      completedAt: _parseDateTime(json['completed_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }
}

enum TodoFilter { all, mine, partners, shared }

enum TodoAssigneeOption { me, partner, shared }
