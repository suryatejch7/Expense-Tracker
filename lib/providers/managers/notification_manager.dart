import '../../models/expense_models.dart';
import '../../services/notification_service.dart';

/// Manages notification scheduling and triggers.
/// Internal delegate used by ExpenseProvider.
class NotificationManager {
  /// Trigger notifications after adding an expense
  Future<void> triggerExpenseNotifications({
    required Expense expense,
    required List<Expense> allExpenses,
    required double monthlyBudget,
    required double categoryBudget,
    required double categorySpent,
    required bool isFirstExpense,
  }) async {
    try {
      if (isFirstExpense) {
        await NotificationService.sendFirstExpenseNotification();
      }

      // Check daily budget
      final todayExpenses = _getExpensesForToday(allExpenses);
      final dailySpent = todayExpenses.fold(0.0, (sum, e) => sum + e.amount);
      final dailyBudget = monthlyBudget / 30;
      await NotificationService.checkDailyBudgetAlert(dailySpent, dailyBudget);

      // Check monthly budget
      final monthlyExpenses = _getExpensesForMonth(allExpenses);
      final monthlySpent = monthlyExpenses.fold(
        0.0,
        (sum, e) => sum + e.amount,
      );
      await NotificationService.checkMonthlyBudgetWarning(
        monthlySpent,
        monthlyBudget,
      );

      // Check category budget
      if (categoryBudget > 0) {
        await NotificationService.checkCategoryBudgetAlert(
          expense.category,
          categorySpent,
          categoryBudget,
        );
      }

      // Analyze spending patterns
      await NotificationService.analyzeSpendingPatterns(allExpenses);

      // Check budget crisis
      await NotificationService.checkBudgetCrisis(monthlySpent, monthlyBudget);
    } catch (e) {
      // Failed to trigger notifications
    }
  }

  /// Schedule periodic notifications
  Future<void> schedulePeriodicNotifications(List<Expense> allExpenses) async {
    try {
      await NotificationService.scheduleWeeklyExpenseReview();
      await _sendWeeklySummaryIfNeeded(allExpenses);
      await _sendMonthlySummaryIfNeeded(allExpenses);
    } catch (e) {
      // Failed to schedule periodic notifications
    }
  }

  List<Expense> _getExpensesForToday(List<Expense> expenses) {
    final today = DateTime.now();
    return expenses.where((expense) {
      return expense.date.year == today.year &&
          expense.date.month == today.month &&
          expense.date.day == today.day;
    }).toList();
  }

  List<Expense> _getExpensesForMonth(List<Expense> expenses) {
    final now = DateTime.now();
    return expenses.where((expense) {
      return expense.date.year == now.year && expense.date.month == now.month;
    }).toList();
  }

  List<Expense> _getExpensesForWeek(List<Expense> expenses) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return expenses.where((expense) {
      return expense.date.isAfter(
            weekStart.subtract(const Duration(days: 1)),
          ) &&
          expense.date.isBefore(weekEnd.add(const Duration(days: 1)));
    }).toList();
  }

  Future<void> _sendWeeklySummaryIfNeeded(List<Expense> expenses) async {
    final now = DateTime.now();
    if (now.weekday == DateTime.sunday) {
      final weeklyExpenses = _getExpensesForWeek(expenses);
      final weeklyTotal = weeklyExpenses.fold(0.0, (sum, e) => sum + e.amount);
      if (weeklyTotal > 0) {
        await NotificationService.sendWeeklySpendingSummary(weeklyTotal);
      }
    }
  }

  Future<void> _sendMonthlySummaryIfNeeded(List<Expense> expenses) async {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;

    if (now.day == lastDayOfMonth) {
      final monthlyExpenses = _getExpensesForMonth(expenses);
      final monthlyTotal = monthlyExpenses.fold(
        0.0,
        (sum, e) => sum + e.amount,
      );

      if (monthlyTotal > 0) {
        final categoryBreakdown = <String, double>{};
        for (final expense in monthlyExpenses) {
          categoryBreakdown[expense.category] =
              (categoryBreakdown[expense.category] ?? 0) + expense.amount;
        }
        await NotificationService.sendMonthlySummary(
          monthlyTotal,
          categoryBreakdown,
        );
        await NotificationService.sendCategoryBreakdown(
          categoryBreakdown,
          monthlyTotal,
        );
      }
    }
  }
}
