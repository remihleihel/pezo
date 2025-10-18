import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    _isInitialized = true;
    print('NotificationService: Initialized successfully');
  }

  static Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    print('NotificationService: Permission status: $status');
    return status.isGranted;
  }

  static Future<void> showBudgetAlert(String category, double spent, double budget) async {
    if (!_isInitialized) await initialize();
    
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'budget_alerts',
        'Budget Alerts',
        channelDescription: 'Notifications when approaching budget limits',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final percentage = (spent / budget * 100).round();
    final remaining = budget - spent;

    await _notifications.show(
      category.hashCode,
      'Budget Alert: $category',
      'You\'ve spent \$${spent.toStringAsFixed(2)} of \$${budget.toStringAsFixed(2)} (${percentage}%). \$${remaining.toStringAsFixed(2)} remaining.',
      notificationDetails,
    );

    print('NotificationService: Budget alert sent for $category');
  }

  static Future<void> showGoalReminder(String goalTitle, double currentAmount, double targetAmount) async {
    if (!_isInitialized) await initialize();
    
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'goal_reminders',
        'Goal Reminders',
        channelDescription: 'Reminders for spending goals',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final percentage = (currentAmount / targetAmount * 100).round();
    final remaining = targetAmount - currentAmount;

    await _notifications.show(
      goalTitle.hashCode,
      'Goal Reminder: $goalTitle',
      'Progress: \$${currentAmount.toStringAsFixed(2)} of \$${targetAmount.toStringAsFixed(2)} (${percentage}%). \$${remaining.toStringAsFixed(2)} to go!',
      notificationDetails,
    );

    print('NotificationService: Goal reminder sent for $goalTitle');
  }

  static Future<void> scheduleBudgetCheck() async {
    if (!_isInitialized) await initialize();
    
    // Schedule daily budget check at 8 PM
    await _notifications.zonedSchedule(
      0,
      'Daily Budget Check',
      'Check your spending progress for today',
      _nextInstanceOfTime(20, 0), // 8 PM
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_checks',
          'Daily Checks',
          channelDescription: 'Daily budget and goal checks',
          importance: Importance.low,
          priority: Priority.low,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    print('NotificationService: Daily budget check scheduled');
  }

  static Future<void> scheduleGoalReminder(String goalTitle, DateTime targetDate) async {
    if (!_isInitialized) await initialize();
    
    // Schedule reminder 3 days before target date
    final reminderDate = targetDate.subtract(const Duration(days: 3));
    if (reminderDate.isAfter(DateTime.now())) {
      await _notifications.zonedSchedule(
        goalTitle.hashCode + 1000, // Different ID to avoid conflicts
        'Goal Deadline Approaching',
        '$goalTitle deadline is in 3 days!',
        tz.TZDateTime.from(reminderDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'goal_deadlines',
            'Goal Deadlines',
            channelDescription: 'Reminders for approaching goal deadlines',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('NotificationService: Goal deadline reminder scheduled for $goalTitle');
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print('NotificationService: Cancelled notification $id');
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('NotificationService: Cancelled all notifications');
  }

  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Helper method to get next instance of a specific time
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return tz.TZDateTime.from(scheduledDate, tz.local);
  }
}
