import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/todo.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
    FlutterLocalNotificationsPlugin();
  
  // Track exact alarm permission status
  bool _hasExactAlarmPermission = false;

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );

    // Request permissions
    await _requestNotificationPermissions();
    
    // Check exact alarm permission
    await _checkExactAlarmPermission();
  }

  Future<void> _requestNotificationPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }
  
  // Check and potentially request exact alarm permission for Android 12+
  Future<void> _checkExactAlarmPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
              
      if (androidImplementation != null) {
        try {
          _hasExactAlarmPermission = await androidImplementation.canScheduleExactNotifications() ?? false;
        } catch (e) {
          // If the method isn't available (older Flutter Local Notifications versions)
          // or if there's another exception, default to false
          _hasExactAlarmPermission = false;
        }
      }
    } else {
      // On iOS, we don't need this specific permission
      _hasExactAlarmPermission = true;
    }
    
    debugPrint('Exact alarm permission status: $_hasExactAlarmPermission');
  }
  
  // Request exact alarm permission on Android 12+
  Future<void> requestExactAlarmPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
              
      if (androidImplementation != null) {
        try {
          await androidImplementation.requestExactAlarmsPermission();
          // Check if permission was granted
          _hasExactAlarmPermission = await androidImplementation.canScheduleExactNotifications() ?? false;
        } catch (e) {
          debugPrint('Error requesting exact alarm permission: $e');
        }
      }
    }
  }

  Future<void> scheduleTodoNotification(Todo todo) async {
    // If task doesn't have a time, don't schedule notification
    if (todo.time == null || todo.time!.isEmpty) {
      return;
    }

    final id = todo.id ?? DateTime.now().millisecondsSinceEpoch % 0x7FFFFFFF;
    
    // Parse time format (expected as HH:mm)
    final timeParts = todo.time!.split(':');
    if (timeParts.length != 2) {
      return;
    }
    
    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    
    if (hour == null || minute == null) {
      return;
    }
    
    // Set notification time (5 minutes before task time)
    final now = DateTime.now();
    DateTime scheduledDate;
    
    if (todo.type == TodoType.weekly && todo.weekday != null) {
      // For weekly tasks, find the appropriate day
      Map<String, int> weekdayMap = {
        'pazartesi': 1, 'salı': 2, 'çarşamba': 3, 'perşembe': 4, 
        'cuma': 5, 'cumartesi': 6, 'pazar': 7
      };
      
      int dayOfWeek = weekdayMap[todo.weekday!.toLowerCase()] ?? now.weekday;
      int daysUntil = dayOfWeek - now.weekday;
      if (daysUntil < 0) daysUntil += 7; // Next week
      
      scheduledDate = DateTime(
        now.year, now.month, now.day + daysUntil, 
        hour, minute
      );
    } else {
      // For daily or today-specific tasks, use today's date
      scheduledDate = DateTime(
        now.year, now.month, now.day, 
        hour, minute
      );
    }
    
    // If time is in the past, cancel scheduling (for today-specific tasks)
    // or assign to the next day (for daily tasks)
    if (scheduledDate.isBefore(now)) {
      if (todo.type == TodoType.today) {
        return; // Cancel notification for today-specific tasks if in the past
      } else {
        // For daily tasks, schedule for the next day
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
    }
    
    // Notify 5 minutes before
    scheduledDate = scheduledDate.subtract(const Duration(minutes: 5));

    // If this time is also in the past, don't send notification
    if (scheduledDate.isBefore(now)) {
      return;
    }
    
    // Choose the appropriate AndroidScheduleMode based on permission status
    final AndroidScheduleMode scheduleMode = _hasExactAlarmPermission 
      ? AndroidScheduleMode.exactAllowWhileIdle 
      : AndroidScheduleMode.inexactAllowWhileIdle;
    
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Hatırlatma: ${todo.title}',
        'Yaklaşan görev: ${todo.time} - ${todo.description}',
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'todo_reminder',
            'Todo Hatırlatıcı',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
      // If exact alarm scheduling failed, try with inexact alarms
      if (_hasExactAlarmPermission && e.toString().contains('exact_alarms_not_permitted')) {
        _hasExactAlarmPermission = false;
        await scheduleTodoNotification(todo); // Retry with inexact alarm
      }
    }
  }
  
  // Clear all notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
  
  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
  
  // Utility function to check and request exact alarm permissions if needed
  Future<bool> checkAndRequestExactAlarmPermissionIfNeeded() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true; // Non-Android platforms don't need this permission
    }
    
    // First check if we already have permission
    await _checkExactAlarmPermission();
    
    if (_hasExactAlarmPermission) {
      return true;
    }
    
    // If we don't have permission, request it
    await requestExactAlarmPermission();
    
    // Check again if permission was granted
    await _checkExactAlarmPermission();
    return _hasExactAlarmPermission;
  }
}