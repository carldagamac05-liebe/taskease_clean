import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class LocalStorageService {
  static Database? _database;
  static LocalStorageService? _instance;

  LocalStorageService._internal();

  static Future<LocalStorageService> getInstance() async {
    if (_instance == null) {
      _instance = LocalStorageService._internal();
      await _instance!._initDatabase();
    }
    return _instance!;
  }

  Future<void> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'taskease.db');
    _database = await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        priority TEXT,
        status TEXT,
        due_date TEXT NOT NULL,
        due_time TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        content TEXT,
        drawing_data TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
  }

  Future<int> insertTask(Map<String, dynamic> task) async {
    task['created_at'] = DateTime.now().toIso8601String();
    return await _database!.insert('tasks', task);
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    return await _database!.query('tasks', orderBy: 'due_date ASC, due_time ASC');
  }

  Future<List<Map<String, dynamic>>> getTasksByDate(String date) async {
    return await _database!.query(
      'tasks',
      where: 'due_date = ?',
      whereArgs: [date],
      orderBy: 'due_time ASC, priority ASC',
    );
  }

  Future<int> updateTask(int id, Map<String, dynamic> task) async {
    return await _database!.update('tasks', task, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTask(int id) async {
    return await _database!.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertNote(Map<String, dynamic> note) async {
    note['created_at'] = DateTime.now().toIso8601String();
    note['updated_at'] = DateTime.now().toIso8601String();
    return await _database!.insert('notes', note);
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    return await _database!.query('notes', orderBy: 'updated_at DESC');
  }

  Future<int> updateNote(int id, Map<String, dynamic> note) async {
    note['updated_at'] = DateTime.now().toIso8601String();
    return await _database!.update('notes', note, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteNote(int id) async {
    return await _database!.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllTasks() async {
    await _database!.delete('tasks');
  }
}
