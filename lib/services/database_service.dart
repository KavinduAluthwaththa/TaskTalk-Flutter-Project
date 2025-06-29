import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  late FirebaseFirestore _firestore;
  late FirebaseAuth _auth;
  String? _userId;

  DatabaseService._internal();

  factory DatabaseService() => _instance;

  Future<void> initialize() async {
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
    
    // Sign in anonymously for simplicity
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
    _userId = _auth.currentUser?.uid;
  }

  CollectionReference get _tasksCollection {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(_userId).collection('tasks');
  }

  // Insert a new task
  Future<String> insertTask(Task task) async {
    try {
      final docRef = await _tasksCollection.add(task.toMap());
      return docRef.id;
    } catch (e) {
      print('Error inserting task: $e');
      rethrow;
    }
  }

  // Get all tasks
  Future<List<Task>> getAllTasks() async {
    try {
      final querySnapshot = await _tasksCollection
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Task.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting all tasks: $e');
      return [];
    }
  }

  // Get incomplete tasks
  Future<List<Task>> getIncompleteTasks() async {
    try {
      final querySnapshot = await _tasksCollection
          .where('isCompleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Task.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting incomplete tasks: $e');
      return [];
    }
  }

  // Update a task
  Future<void> updateTask(Task task) async {
    try {
      if (task.id == null) throw Exception('Task ID cannot be null for update');
      
      await _tasksCollection.doc(task.id).update(task.toMap());
    } catch (e) {
      print('Error updating task: $e');
      rethrow;
    }
  }

  // Delete a task
  Future<void> deleteTask(String id) async {
    try {
      await _tasksCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting task: $e');
      rethrow;
    }
  }

  // Mark task as completed
  Future<void> markTaskCompleted(String id) async {
    try {
      await _tasksCollection.doc(id).update({'isCompleted': true});
    } catch (e) {
      print('Error marking task as completed: $e');
      rethrow;
    }
  }

  // Get tasks with reminders for notifications
  Future<List<Task>> getTasksWithReminders() async {
    try {
      final querySnapshot = await _tasksCollection
          .where('hasReminder', isEqualTo: true)
          .where('isCompleted', isEqualTo: false)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Task.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting tasks with reminders: $e');
      return [];
    }
  }

  // Get real-time stream of tasks
  Stream<List<Task>> getTasksStream() {
    try {
      return _tasksCollection
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Task.fromFirestore(doc))
              .toList());
    } catch (e) {
      print('Error getting tasks stream: $e');
      return Stream.value([]);
    }
  }

  // Get real-time stream of incomplete tasks
  Stream<List<Task>> getIncompleteTasksStream() {
    try {
      return _tasksCollection
          .where('isCompleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Task.fromFirestore(doc))
              .toList());
    } catch (e) {
      print('Error getting incomplete tasks stream: $e');
      return Stream.value([]);
    }
  }

  // Sign out user
  Future<void> signOut() async {
    await _auth.signOut();
    _userId = null;
  }

  // Get current user ID
  String? get currentUserId => _userId;
}
