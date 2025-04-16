import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todo.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'todo_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        time TEXT,
        weekday TEXT,
        isDone INTEGER NOT NULL,
        type INTEGER NOT NULL
      )
    ''');
  }

  // CRUD Operations

  // Create
  Future<int> insertTodo(Todo todo) async {
    Database db = await database;
    return await db.insert('todos', todo.toMap());
  }

  // Read
  Future<List<Todo>> getTodos() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('todos');
    return List.generate(maps.length, (i) => Todo.fromMap(maps[i]));
  }

  // Get daily todos
  Future<List<Todo>> getDailyTodos() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'type = ?',
      whereArgs: [TodoType.daily.index],
    );
    return List.generate(maps.length, (i) => Todo.fromMap(maps[i]));
  }

  // Get weekly todos for a specific day
  Future<List<Todo>> getWeeklyTodosByDay(String weekday) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'type = ? AND weekday = ?',
      whereArgs: [TodoType.weekly.index, weekday],
    );
    return List.generate(maps.length, (i) => Todo.fromMap(maps[i]));
  }

  // Get today's specific todos
  Future<List<Todo>> getTodaySpecificTodos() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'type = ?',
      whereArgs: [TodoType.today.index],
    );
    return List.generate(maps.length, (i) => Todo.fromMap(maps[i]));
  }

  // Get all todos for today (combines daily, today-specific, and weekly for current weekday)
  Future<List<Todo>> getAllTodosForToday() async {
    String currentWeekday = DateFormat('EEEE', 'tr_TR').format(DateTime.now()).toLowerCase();
    
    // Map English weekday to Turkish
    Map<String, String> weekdayMap = {
      'monday': 'pazartesi',
      'tuesday': 'salı',
      'wednesday': 'çarşamba',
      'thursday': 'perşembe',
      'friday': 'cuma',
      'saturday': 'cumartesi',
      'sunday': 'pazar',
    };
    
    String turkishWeekday = weekdayMap[currentWeekday.toLowerCase()] ?? currentWeekday;
    
    List<Todo> dailyTodos = await getDailyTodos();
    List<Todo> weeklyTodosForToday = await getWeeklyTodosByDay(turkishWeekday);
    List<Todo> todaySpecificTodos = await getTodaySpecificTodos();
    
    return [...dailyTodos, ...weeklyTodosForToday, ...todaySpecificTodos];
  }

  // Update
  Future<int> updateTodo(Todo todo) async {
    Database db = await database;
    return await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  // Delete
  Future<int> deleteTodo(int id) async {
    Database db = await database;
    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Toggle todo completion status
  Future<void> toggleTodoStatus(int id, bool isDone) async {
    Database db = await database;
    await db.update(
      'todos',
      {'isDone': isDone ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}