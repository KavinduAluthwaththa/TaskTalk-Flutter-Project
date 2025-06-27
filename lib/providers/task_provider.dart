import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/text_to_speech_service.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final TextToSpeechService _ttsService = TextToSpeechService();
  
  List<Task> _tasks = [];
  bool _isLoading = false;

  List<Task> get tasks => _tasks;
  List<Task> get incompleteTasks => _tasks.where((task) => !task.isCompleted).toList();
  List<Task> get completedTasks => _tasks.where((task) => task.isCompleted).toList();
  bool get isLoading => _isLoading;

  TaskProvider() {
    loadTasks();
  }

  Future<void> loadTasks() async {
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
    try {
      final id = await _databaseService.insertTask(task);
      final newTask = task.copyWith(id: id);
      _tasks.insert(0, newTask);
      notifyListeners();
      
      // Speak confirmation
      await _ttsService.speak("Task added: ${task.title}");
    } catch (e) {
      print('Error adding task: $e');
      await _ttsService.speak("Sorry, there was an error adding the task.");
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _databaseService.updateTask(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating task: $e');
    }
  }

  Future<void> deleteTask(int taskId) async {
    try {
      await _databaseService.deleteTask(taskId);
      final task = _tasks.firstWhere((t) => t.id == taskId);
      _tasks.removeWhere((t) => t.id == taskId);
      notifyListeners();
      
      // Speak confirmation
      await _ttsService.speak("Task deleted: ${task.title}");
    } catch (e) {
      print('Error deleting task: $e');
      await _ttsService.speak("Sorry, there was an error deleting the task.");
    }
  }

  Future<void> toggleTaskCompletion(int taskId) async {
    try {
      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex == -1) return;

      final task = _tasks[taskIndex];
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      
      await _databaseService.updateTask(updatedTask);
      _tasks[taskIndex] = updatedTask;
      notifyListeners();
      
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
}
