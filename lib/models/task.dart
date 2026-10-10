class Task {
  final String? id;
  final String title;
  final String description;
  final String assignee;
  final DateTime dueDate;
  final String priority;
  final String status;
  final DateTime createdAt;

  const Task({
    this.id,
    required this.title,
    required this.description,
    required this.assignee,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.createdAt,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? assignee,
    DateTime? dueDate,
    String? priority,
    String? status,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignee: assignee ?? this.assignee,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assignee': assignee,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'priority': priority,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      assignee: map['assignee'] as String? ?? '',
      dueDate: _readDate(map['dueDate']),
      priority: map['priority'] as String? ?? 'Medium',
      status: map['status'] as String? ?? 'To Do',
      createdAt: _readDate(map['createdAt']),
    );
  }

  static DateTime _readDate(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
