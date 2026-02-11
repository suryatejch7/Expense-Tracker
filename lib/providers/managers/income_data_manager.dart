import '../../models/expense_models.dart';
import '../../services/supabase_service.dart';

/// Manages income data: CRUD and loading.
/// Internal delegate used by ExpenseProvider.
class IncomeDataManager {
  final List<Income> _incomes = [];

  List<Income> get incomes => _incomes;

  /// Load incomes from backend
  Future<void> loadIncomes(int userId) async {
    try {
      final incomes = await ExpenseSupabaseService.getIncomes(userId: userId);
      final sortedIncomes = List<Income>.from(incomes);
      sortedIncomes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (sortedIncomes.isNotEmpty || _incomes.isEmpty) {
        _incomes.clear();
        _incomes.addAll(sortedIncomes);
      }
    } catch (e) {
      // Handle error silently - keep existing data
    }
  }

  /// Add income to backend and local list
  Future<void> addIncome(Income income, int userId) async {
    final incomeId = await ExpenseSupabaseService.addIncome(income, userId);
    final incomeWithId = income.copyWith(id: incomeId);

    final existingIndex = _incomes.indexWhere((i) => i.id == incomeId);
    if (existingIndex == -1) {
      _incomes.insert(0, incomeWithId);
    }
  }

  /// Update income in backend and local list
  Future<void> updateIncome(Income income, int userId) async {
    await ExpenseSupabaseService.updateIncome(income, userId);
    final index = _incomes.indexWhere((i) => i.id == income.id);
    if (index != -1) {
      _incomes[index] = income;
    }
  }

  /// Delete income from backend and local list
  Future<void> deleteIncome(String incomeId, int userId) async {
    await ExpenseSupabaseService.deleteIncome(incomeId, userId);
    _incomes.removeWhere((income) => income.id == incomeId);
  }

  /// Clear all data
  void clear() {
    _incomes.clear();
  }
}
