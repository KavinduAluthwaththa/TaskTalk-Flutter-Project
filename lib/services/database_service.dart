import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  factory DatabaseService() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'tasks_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        dueTime INTEGER,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL,
        hasReminder INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // Insert a new task
  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  // Get all tasks
  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  // Get incomplete tasks
  Future<List<Task>> getIncompleteTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'isCompleted = ?',
      whereArgs: [0],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  // Update a task
  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // Delete a task
  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Mark task as completed
  Future<int> markTaskCompleted(int id) async {
    final db = await database;
    return await db.update(
      'tasks',
      {'isCompleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get tasks with reminders for notifications
  Future<List<Task>> getTasksWithReminders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'hasReminder = ? AND isCompleted = ?',
      whereArgs: [1, 0],
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }
}
