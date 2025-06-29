import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String? id;
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

  // Convert to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dueTime': dueTime != null ? Timestamp.fromDate(dueTime!) : null,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'hasReminder': hasReminder,
    };
  }

  // Create Task from Firestore DocumentSnapshot
  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      dueTime: data['dueTime'] != null 
          ? (data['dueTime'] as Timestamp).toDate()
          : null,
      isCompleted: data['isCompleted'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      hasReminder: data['hasReminder'] ?? false,
    );
  }

  // Create Task from Map (for backward compatibility)
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueTime: map['dueTime'] != null
          ? map['dueTime'] is Timestamp
              ? (map['dueTime'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['dueTime'])
          : null,
      isCompleted: map['isCompleted'] is bool 
          ? map['isCompleted'] 
          : map['isCompleted'] == 1,
      createdAt: map['createdAt'] != null
          ? map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      hasReminder: map['hasReminder'] is bool 
          ? map['hasReminder'] 
          : map['hasReminder'] == 1,
    );
  }

  // Create a copy with modifications
  Task copyWith({
    String? id,
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
