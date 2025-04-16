import 'package:flutter/foundation.dart';
import '../models/todo.dart';
import '../helpers/database_helper.dart';
import 'package:intl/intl.dart';

class TodoProvider with ChangeNotifier {
  List<Todo> _dailyTodos = [];
  List<Todo> _weeklyTodos = [];
  List<Todo> _todayTodos = [];
  List<Todo> _todaySpecificTodos = [];
  
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  List<Todo> get dailyTodos => _dailyTodos;
  List<Todo> get weeklyTodos => _weeklyTodos;
  List<Todo> get todayTodos => _todayTodos;
  List<Todo> get todaySpecificTodos => _todaySpecificTodos;

  TodoProvider() {
    _loadTodos();
  }

  // Load all todos from the database
  Future<void> _loadTodos() async {
    _dailyTodos = await _dbHelper.getDailyTodos();
    
    // Load all weekly todos
    final allTodos = await _dbHelper.getTodos();
    _weeklyTodos = allTodos.where((todo) => todo.type == TodoType.weekly).toList();
    
    // Load today's specific todos
    _todaySpecificTodos = await _dbHelper.getTodaySpecificTodos();
    
    // Load all of today's todos (daily + weekly for today + today specific)
    _todayTodos = await _dbHelper.getAllTodosForToday();
    
    notifyListeners();
  }
  
  // Add a new todo
  Future<void> addTodo(Todo todo) async {
    await _dbHelper.insertTodo(todo);
    await _loadTodos();
  }
  
  // Update a todo
  Future<void> updateTodo(Todo todo) async {
    await _dbHelper.updateTodo(todo);
    await _loadTodos();
  }
  
  // Delete a todo
  Future<void> deleteTodo(int id) async {
    await _dbHelper.deleteTodo(id);
    await _loadTodos();
  }
  
  // Toggle todo completion status
  Future<void> toggleTodoStatus(Todo todo) async {
    await _dbHelper.toggleTodoStatus(todo.id!, !todo.isDone);
    await _loadTodos();
  }
  
  // Get todos for a specific weekday
  List<Todo> getWeeklyTodosByDay(String weekday) {
    return _weeklyTodos.where((todo) => todo.weekday == weekday.toLowerCase()).toList();
  }
  
  // Get the current Turkish weekday
  String getCurrentWeekday() {
    // Initialize the locale data
    String currentWeekday = DateFormat('EEEE').format(DateTime.now()).toLowerCase();
    
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
    
    return weekdayMap[currentWeekday] ?? currentWeekday;
  }
  
  // Get all weekdays in Turkish
  List<String> getAllWeekdays() {
    return [
      'pazartesi',
      'salı',
      'çarşamba',
      'perşembe',
      'cuma',
      'cumartesi',
      'pazar'
    ];
  }
}