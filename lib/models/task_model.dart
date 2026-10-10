enum SlaStatus { onTrack, atRisk, overdue, completed }

class TaskRecord {
  const TaskRecord({
    required this.id,
    required this.title,
    required this.deadline,
    required this.status,
    required this.priority,
    this.description = '',
    this.assignee,
    this.assigneeId,
  });

  final String id;
  final String title;
  final DateTime deadline;
  final String status;
  final String priority;
  final String description;
  final String? assignee;
  final String? assigneeId;

  factory TaskRecord.fromMap(Map<String, Object?> map) {
    return TaskRecord(
      id: _requiredString(map, 'id'),
      title: _requiredString(map, 'title'),
      deadline: DateTime.parse(_requiredString(map, 'deadline')),
      status: _requiredString(map, 'status'),
      priority: _requiredString(map, 'priority'),
      description: map['description'] as String? ?? '',
      assignee: map['assignee_name'] as String?,
      assigneeId: map['assigned_to_id'] as String?,
    );
  }

  SlaStatus slaStatusAt(DateTime now) {
    if (status.trim().toLowerCase() == 'completed') {
      return SlaStatus.completed;
    }

    final dueDate = DateTime(deadline.year, deadline.month, deadline.day);
    final today = DateTime(now.year, now.month, now.day);
    if (dueDate.isBefore(today)) {
      return SlaStatus.overdue;
    }
    if (dueDate.difference(today).inDays <= 2) {
      return SlaStatus.atRisk;
    }
    return SlaStatus.onTrack;
  }

  static String _requiredString(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Task field "$key" must be a non-empty string.');
    }
    return value;
  }
}

extension SlaStatusLabel on SlaStatus {
  String get label {
    switch (this) {
      case SlaStatus.onTrack:
        return 'On Track';
      case SlaStatus.atRisk:
        return 'At Risk';
      case SlaStatus.overdue:
        return 'Overdue';
      case SlaStatus.completed:
        return 'Completed';
    }
  }
}
