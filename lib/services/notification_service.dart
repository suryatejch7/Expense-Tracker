import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense_models.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;
  static SharedPreferences? _prefs;

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);

    // Request permissions
    await _requestPermissions();

    _isInitialized = true;
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    return _prefs?.getBool('notifications_enabled') ?? true;
  }

  /// Enable/disable notifications
  static Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool('notifications_enabled', enabled);
    if (!enabled) {
      await _notificationsPlugin.cancelAll();
    }
  }

  // ============================================================================
  // BUDGET & SPENDING NOTIFICATIONS
  // ============================================================================

  /// Check daily budget and send alerts if needed
  static Future<void> checkDailyBudgetAlert(
    double dailySpent,
    double dailyBudget,
  ) async {
    if (!await areNotificationsEnabled()) return;
    if (dailyBudget <= 0) return;

    final percentage = (dailySpent / dailyBudget * 100).round();

    if (percentage >= 80 && percentage < 100) {
      await _showNotification(
        'Daily Budget Alert',
        'You\'ve spent $percentage% of your daily budget (₹${dailySpent.toInt()}/${dailyBudget.toInt()})',
        importance: Importance.high,
      );
    } else if (percentage >= 100) {
      final overspent = dailySpent - dailyBudget;
      await _showNotification(
        'Daily Budget Exceeded',
        'You\'ve exceeded your daily budget by ₹${overspent.toInt()}',
        importance: Importance.max,
      );
    }
  }

  /// Check monthly budget and send warnings
  static Future<void> checkMonthlyBudgetWarning(
    double monthlySpent,
    double monthlyBudget,
  ) async {
    if (!await areNotificationsEnabled()) return;
    if (monthlyBudget <= 0) return;

    final percentage = (monthlySpent / monthlyBudget * 100).round();

    if (percentage >= 90 && percentage < 100) {
      await _showNotification(
        'Monthly Budget Warning',
        'You\'ve spent $percentage% of your monthly budget (₹${monthlySpent.toInt()}/${monthlyBudget.toInt()})',
        importance: Importance.high,
      );
    } else if (percentage >= 100) {
      final overspent = monthlySpent - monthlyBudget;
      await _showNotification(
        'Monthly Budget Exceeded',
        'You\'ve exceeded your monthly budget by ₹${overspent.toInt()}',
        importance: Importance.max,
      );
    }
  }

  /// Check category budget alerts
  static Future<void> checkCategoryBudgetAlert(
    String categoryName,
    double categorySpent,
    double categoryBudget,
  ) async {
    if (!await areNotificationsEnabled()) return;
    if (categoryBudget <= 0) return;

    final percentage = (categorySpent / categoryBudget * 100).round();

    if (percentage >= 90) {
      await _showNotification(
        'Category Budget Alert',
        'You\'ve spent $percentage% of your $categoryName budget (₹${categorySpent.toInt()}/${categoryBudget.toInt()})',
        importance: Importance.high,
      );
    }
  }

  /// Send weekly spending summary
  static Future<void> sendWeeklySpendingSummary(double weeklySpent) async {
    if (!await areNotificationsEnabled()) return;

    await _showNotification(
      'Weekly Spending Summary',
      'This week you spent ₹${weeklySpent.toInt()}',
      importance: Importance.defaultImportance,
    );
  }

  // ============================================================================
  // REMINDER NOTIFICATIONS
  // ============================================================================

  /// Schedule weekly expense review
  static Future<void> scheduleWeeklyExpenseReview() async {
    if (!await areNotificationsEnabled()) return;

    // Schedule for Sunday 9 PM
    await _scheduleWeeklyNotification(
      'Weekly Expense Review',
      'Review your expenses for this week',
      weekday: DateTime.sunday,
      hour: 21,
      minute: 0,
    );
  }

  // ============================================================================
  // ACHIEVEMENT & MILESTONE NOTIFICATIONS
  // ============================================================================

  /// Send first expense welcome notification
  static Future<void> sendFirstExpenseNotification() async {
    if (!await areNotificationsEnabled()) return;

    await _showNotification(
      'Welcome!',
      'You\'ve logged your first expense. Great start!',
      importance: Importance.defaultImportance,
    );
  }

  // ============================================================================
  // FOOD & LIFESTYLE NOTIFICATIONS
  // ============================================================================

  /// Check food spending alerts
  static Future<void> checkFoodSpendingAlert(
    double weeklyFoodSpent,
    double weeklyFoodBudget,
  ) async {
    if (!await areNotificationsEnabled()) return;
    if (weeklyFoodBudget <= 0) return;

    final percentage = (weeklyFoodSpent / weeklyFoodBudget * 100).round();

    if (percentage >= 80) {
      await _showNotification(
        'Food Spending Alert',
        'You\'ve spent ₹${weeklyFoodSpent.toInt()} on food this week ($percentage% of budget)',
        importance: Importance.high,
      );
    }
  }

  // ============================================================================
  // FINANCIAL INSIGHTS NOTIFICATIONS
  // ============================================================================

  /// Analyze spending patterns
  static Future<void> analyzeSpendingPatterns(List<Expense> expenses) async {
    if (!await areNotificationsEnabled()) return;
    if (expenses.length < 7) return;

    final weekendExpenses = expenses.where((e) {
      final weekday = e.date.weekday;
      return weekday == DateTime.saturday || weekday == DateTime.sunday;
    }).toList();

    final weekdayExpenses = expenses.where((e) {
      final weekday = e.date.weekday;
      return weekday != DateTime.saturday && weekday != DateTime.sunday;
    }).toList();

    if (weekendExpenses.isNotEmpty && weekdayExpenses.isNotEmpty) {
      final weekendAvg =
          weekendExpenses.fold(0.0, (sum, e) => sum + e.amount) /
          weekendExpenses.length;
      final weekdayAvg =
          weekdayExpenses.fold(0.0, (sum, e) => sum + e.amount) /
          weekdayExpenses.length;

      if (weekendAvg > weekdayAvg * 1.4) {
        final percentage = ((weekendAvg - weekdayAvg) / weekdayAvg * 100)
            .round();
        await _showNotification(
          'Spending Pattern Detected',
          'You spend $percentage% more on weekends',
          importance: Importance.defaultImportance,
        );
      }
    }
  }

  /// Analyze spending trends
  static Future<void> analyzeSpendingTrends(
    List<Expense> currentMonthExpenses,
    List<Expense> previousMonthExpenses,
  ) async {
    if (!await areNotificationsEnabled()) return;
    if (currentMonthExpenses.isEmpty || previousMonthExpenses.isEmpty) return;

    final currentTotal = currentMonthExpenses.fold(
      0.0,
      (sum, e) => sum + e.amount,
    );
    final previousTotal = previousMonthExpenses.fold(
      0.0,
      (sum, e) => sum + e.amount,
    );

    final changePercentage =
        ((currentTotal - previousTotal) / previousTotal * 100).round();

    if (changePercentage.abs() >= 15) {
      final direction = changePercentage > 0 ? 'increased' : 'decreased';
      await _showNotification(
        'Spending Trend Analysis',
        'Your expenses $direction by ${changePercentage.abs()}% this month',
        importance: Importance.defaultImportance,
      );
    }
  }

  // ============================================================================
  // ANALYTICS & REPORT NOTIFICATIONS
  // ============================================================================

  /// Send weekly spending report
  static Future<void> sendWeeklySpendingReport(
    double weeklyTotal,
    Map<String, double> categoryBreakdown,
  ) async {
    if (!await areNotificationsEnabled()) return;

    final topCategory = categoryBreakdown.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    await _showNotification(
      'Weekly Spending Report',
      'Total: ₹${weeklyTotal.toInt()}. Top category: ${topCategory.key} (${(topCategory.value / weeklyTotal * 100).round()}%)',
      importance: Importance.defaultImportance,
    );
  }

  /// Send monthly summary
  static Future<void> sendMonthlySummary(
    double monthlyTotal,
    Map<String, double> categoryBreakdown,
  ) async {
    if (!await areNotificationsEnabled()) return;

    await _showNotification(
      'Monthly Summary Available',
      'You spent ₹${monthlyTotal.toInt()} this month. View detailed breakdown in the app.',
      importance: Importance.defaultImportance,
    );
  }

  /// Send category breakdown
  static Future<void> sendCategoryBreakdown(
    Map<String, double> categoryBreakdown,
    double totalSpent,
  ) async {
    if (!await areNotificationsEnabled()) return;
    if (categoryBreakdown.isEmpty) return;

    final sortedCategories = categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top3 = sortedCategories.take(3).toList();
    final breakdown = top3
        .map((e) => '${e.key}: ${(e.value / totalSpent * 100).round()}%')
        .join(', ');

    await _showNotification(
      'Category Breakdown',
      breakdown,
      importance: Importance.defaultImportance,
    );
  }

  // ============================================================================
  // WARNING & ALERT NOTIFICATIONS
  // ============================================================================

  /// Check for budget crisis
  static Future<void> checkBudgetCrisis(
    double monthlySpent,
    double monthlyBudget,
  ) async {
    if (!await areNotificationsEnabled()) return;
    if (monthlyBudget <= 0) return;

    final percentage = (monthlySpent / monthlyBudget * 100).round();

    if (percentage >= 150) {
      await _showNotification(
        'Budget Crisis Alert!',
        'You\'re $percentage% over budget this month. Consider reviewing your spending.',
        importance: Importance.max,
      );
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Show a notification with a deterministic ID based on title
  static Future<void> _showNotification(
    String title,
    String body, {
    Importance importance = Importance.defaultImportance,
  }) async {
    // Use title hashCode for deterministic IDs — same alert type replaces previous
    final id = title.hashCode.abs() % 100000;
    await _notificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'expense_tracker',
          'Expense Tracker Notifications',
          importance: importance,
          priority: _getPriorityFromImportance(importance),
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Schedule weekly notification
  static Future<void> _scheduleWeeklyNotification(
    String title,
    String body, {
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    // Deterministic ID based on title so rescheduling replaces existing
    final id = title.hashCode.abs() % 100000;
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfWeekday(weekday, hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'expense_tracker_weekly',
          'Weekly Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Get next instance of weekday
  static tz.TZDateTime _nextInstanceOfWeekday(
    int weekday,
    int hour,
    int minute,
  ) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Convert importance to priority
  static Priority _getPriorityFromImportance(Importance importance) {
    switch (importance) {
      case Importance.max:
        return Priority.max;
      case Importance.high:
        return Priority.high;
      case Importance.defaultImportance:
        return Priority.defaultPriority;
      case Importance.low:
        return Priority.low;
      case Importance.min:
        return Priority.min;
      default:
        return Priority.defaultPriority;
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Cancel specific notification
  static Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
