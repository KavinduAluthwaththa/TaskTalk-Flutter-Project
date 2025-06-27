class Task {
  final int? id;
  final String title;
  final String? description;
  final DateTime? dueTime;
  final bool isCompleted;
  final DateTime createdAt;
  final bool hasReminder;

  Task({
    this.id,
    required this.title,
    this.description,
    this.dueTime,
    this.isCompleted = false,
    DateTime? createdAt,
    this.hasReminder = false,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueTime': dueTime?.millisecondsSinceEpoch,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'hasReminder': hasReminder ? 1 : 0,
    };
  }

  // Create Task from Map (database)
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueTime: map['dueTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dueTime'])
          : null,
      isCompleted: map['isCompleted'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      hasReminder: map['hasReminder'] == 1,
    );
  }

  // Create a copy with modifications
  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueTime,
    bool? isCompleted,
    DateTime? createdAt,
    bool? hasReminder,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueTime: dueTime ?? this.dueTime,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      hasReminder: hasReminder ?? this.hasReminder,
    );
  }

  @override
  String toString() {
    return 'Task{id: $id, title: $title, description: $description, dueTime: $dueTime, isCompleted: $isCompleted, createdAt: $createdAt, hasReminder: $hasReminder}';
  }
}
