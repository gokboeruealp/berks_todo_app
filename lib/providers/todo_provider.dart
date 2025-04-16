import 'package:flutter/foundation.dart';
import '../models/todo.dart';
import '../helpers/database_helper.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../services/csv_service.dart';

class TodoProvider with ChangeNotifier {
  List<Todo> _dailyTodos = [];
  List<Todo> _weeklyTodos = [];
  List<Todo> _todayTodos = [];
  List<Todo> _todaySpecificTodos = [];
  
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();
  final CsvService _csvService = CsvService();
  
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

    allTodos.sort((a, b) {
      if (a.time == null || b.time == null) return 0;
      return DateFormat.Hm().parse(a.time!).compareTo(DateFormat.Hm().parse(b.time!));
    });

    _weeklyTodos = allTodos.where((todo) => todo.type == TodoType.weekly).toList();
    
    // Load today's specific todos
    _todaySpecificTodos = await _dbHelper.getTodaySpecificTodos();

    _todaySpecificTodos.sort((a, b) {
      if (a.time == null || b.time == null) return 0;
      return DateFormat.Hm().parse(a.time!).compareTo(DateFormat.Hm().parse(b.time!));
    });
    
    // Load all of today's todos (daily + weekly for today + today specific)
    _todayTodos = await _dbHelper.getAllTodosForToday();

    _todayTodos.sort((a, b) {
      if (a.time == null || b.time == null) return 0;
      return DateFormat.Hm().parse(a.time!).compareTo(DateFormat.Hm().parse(b.time!));
    });
    
    // Plan all notifications for non-completed todos
    _scheduleAllNotifications();
    
    notifyListeners();
  }
  
  // Schedule notifications for all active todos
  Future<void> _scheduleAllNotifications() async {
    // Cancel all existing notifications first
    await _notificationService.cancelAllNotifications();
    
    // Schedule notifications for daily todos
    for (var todo in _dailyTodos) {
      if (!todo.isDone && todo.time != null) {
        await _notificationService.scheduleTodoNotification(todo);
      }
    }
    
    // Schedule notifications for weekly todos
    for (var todo in _weeklyTodos) {
      if (!todo.isDone && todo.time != null) {
        await _notificationService.scheduleTodoNotification(todo);
      }
    }
    
    // Schedule notifications for today specific todos
    for (var todo in _todaySpecificTodos) {
      if (!todo.isDone && todo.time != null) {
        await _notificationService.scheduleTodoNotification(todo);
      }
    }
  }
  
  // Add a new todo
  Future<void> addTodo(Todo todo) async {
    await _dbHelper.insertTodo(todo);
    
    // Schedule notification for the new todo (if not completed and has a time)
    if (!todo.isDone && todo.time != null) {
      // Check permission before scheduling
      await _notificationService.checkAndRequestExactAlarmPermissionIfNeeded();
      await _notificationService.scheduleTodoNotification(todo);
    }
    
    await _loadTodos();
  }
  
  // Update a todo
  Future<void> updateTodo(Todo todo) async {
    await _dbHelper.updateTodo(todo);
    
    // First cancel old notification
    if (todo.id != null) {
      await _notificationService.cancelNotification(todo.id!);
    }
    
    // If todo is not completed and has a time, schedule a new notification
    if (!todo.isDone && todo.time != null) {
      // Check permission before scheduling
      await _notificationService.checkAndRequestExactAlarmPermissionIfNeeded();
      await _notificationService.scheduleTodoNotification(todo);
    }
    
    await _loadTodos();
  }
  
  // Delete a todo
  Future<void> deleteTodo(int id) async {
    // Bildirimi iptal et
    await _notificationService.cancelNotification(id);
    
    await _dbHelper.deleteTodo(id);
    await _loadTodos();
  }
  
  // Toggle todo completion status
  Future<void> toggleTodoStatus(Todo todo) async {
    await _dbHelper.toggleTodoStatus(todo.id!, !todo.isDone);
    
    // Todo tamamlandıysa bildirimi iptal et, tamamlanmadıysa ve zamanı varsa yeniden planla
    if (todo.id != null) {
      if (!todo.isDone) { // Şimdi tamamlanacak
        await _notificationService.cancelNotification(todo.id!);
      } else if (todo.time != null) { // Tamamlama işlemi geri alındıysa
        await _notificationService.scheduleTodoNotification(
          todo.copyWith(isDone: false)
        );
      }
    }
    
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

  // Export all todos to a CSV file with file picker
  Future<String?> exportToCsv({String defaultFileName = 'todos.csv'}) async {
    // Get all todos
    final List<Todo> allTodos = await _dbHelper.getTodos();
    // Export to CSV with file picker
    return _csvService.exportToCsvFile(allTodos, defaultFileName: defaultFileName);
  }
  
  // Import todos from a CSV file with enhanced file picker
  Future<int> importFromCsv() async {
    try {
      // Import todos from CSV with enhanced file picker
      final List<Todo> importedTodos = await _csvService.importFromCsvFile();
      
      // If we have imported todos
      if (importedTodos.isNotEmpty) {
        int importedCount = 0;
        
        // Add each todo to the database
        for (var todo in importedTodos) {
          // Create a new todo without the id to avoid conflicts
          final newTodo = Todo(
            title: todo.title,
            description: todo.description,
            time: todo.time,
            weekday: todo.weekday,
            isDone: todo.isDone,
            type: todo.type,
          );
          
          await addTodo(newTodo);
          importedCount++;
        }
        
        return importedCount;
      }
    } catch (e) {
      debugPrint('Todo içe aktarma hatası: $e');
      rethrow;
    }
    return 0;
  }
}