import 'package:flutter/material.dart';
import 'dart:async';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/text_to_speech_service.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final TextToSpeechService _ttsService = TextToSpeechService();
  
  List<Task> _tasks = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  StreamSubscription<List<Task>>? _tasksSubscription;

  List<Task> get tasks => _tasks;
  List<Task> get incompleteTasks => _tasks.where((task) => !task.isCompleted).toList();
  List<Task> get completedTasks => _tasks.where((task) => task.isCompleted).toList();
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  TaskProvider() {
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _databaseService.initialize();
      _isInitialized = true;
      _subscribeToTasks();
    } catch (e) {
      print('Error initializing TaskProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeToTasks() {
    _tasksSubscription?.cancel();
    _tasksSubscription = _databaseService.getTasksStream().listen(
      (tasks) {
        _tasks = tasks;
        notifyListeners();
      },
      onError: (error) {
        print('Error in tasks stream: $error');
      },
    );
  }

  Future<void> loadTasks() async {
    if (!_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await _databaseService.getAllTasks();
    } catch (e) {
      print('Error loading tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(Task task) async {
    if (!_isInitialized) {
      await _ttsService.speak("Please wait, the app is still loading.");
      return;
    }

    try {
      await _databaseService.insertTask(task);
      // Note: We don't need to manually update the list since we're listening to the stream
      
      // Speak confirmation
      await _ttsService.speak("Task added: ${task.title}");
    } catch (e) {
      print('Error adding task: $e');
      await _ttsService.speak("Sorry, there was an error adding the task.");
    }
  }

  Future<void> updateTask(Task task) async {
    if (!_isInitialized || task.id == null) return;

    try {
      await _databaseService.updateTask(task);
      // The stream will automatically update the UI
    } catch (e) {
      print('Error updating task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    if (!_isInitialized) return;

    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      await _databaseService.deleteTask(taskId);
      // The stream will automatically update the UI
      
      // Speak confirmation
      await _ttsService.speak("Task deleted: ${task.title}");
    } catch (e) {
      print('Error deleting task: $e');
      await _ttsService.speak("Sorry, there was an error deleting the task.");
    }
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    if (!_isInitialized) return;

    try {
      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex == -1) return;

      final task = _tasks[taskIndex];
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      
      await _databaseService.updateTask(updatedTask);
      // The stream will automatically update the UI
      
      // Speak confirmation
      if (updatedTask.isCompleted) {
        await _ttsService.speak("Task completed: ${task.title}");
      } else {
        await _ttsService.speak("Task marked as incomplete: ${task.title}");
      }
    } catch (e) {
      print('Error toggling task completion: $e');
    }
  }

  Future<void> speakAllTasks() async {
    if (incompleteTasks.isEmpty) {
      await _ttsService.speak("You have no pending tasks.");
      return;
    }

    final taskTitles = incompleteTasks.map((task) => task.title).toList();
    await _ttsService.speakTaskList(taskTitles);
  }

  Future<void> speakTask(Task task) async {
    await _ttsService.speakTask(
      task.title,
      description: task.description,
      dueTime: task.dueTime,
    );
  }

  // Get tasks due today
  List<Task> get tasksToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return incompleteTasks.where((task) {
      if (task.dueTime == null) return false;
      return task.dueTime!.isAfter(today) && task.dueTime!.isBefore(tomorrow);
    }).toList();
  }

  // Get overdue tasks
  List<Task> get overdueTasks {
    final now = DateTime.now();
    return incompleteTasks.where((task) {
      if (task.dueTime == null) return false;
      return task.dueTime!.isBefore(now);
    }).toList();
  }

  // Get upcoming tasks (next 7 days)
  List<Task> get upcomingTasks {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    return incompleteTasks.where((task) {
      if (task.dueTime == null) return false;
      return task.dueTime!.isAfter(now) && task.dueTime!.isBefore(nextWeek);
    }).toList();
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }
}
