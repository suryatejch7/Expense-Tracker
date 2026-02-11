import '../../models/expense_models.dart';
import '../../services/supabase_service.dart';

/// Manages bank account CRUD operations.
/// Internal delegate used by ExpenseProvider.
class AccountManager {
  final List<BankAccount> _accounts = [];

  List<BankAccount> get accounts => _accounts;

  /// Get the default account
  BankAccount? get defaultAccount {
    if (_accounts.isEmpty) return null;
    return _accounts.firstWhere(
      (acc) => acc.isDefault,
      orElse: () => _accounts.first,
    );
  }

  void initialize(List<BankAccount> accounts) {
    _accounts.clear();
    _accounts.addAll(accounts);
  }

  /// Get account by ID
  BankAccount? getAccountById(String accountId) {
    final account = _accounts.firstWhere(
      (acc) => acc.id == accountId,
      orElse: () => BankAccount(id: '', name: ''),
    );
    return account.id.isEmpty ? null : account;
  }

  /// Get account name by ID
  String getAccountName(String? accountId) {
    if (accountId == null || accountId.isEmpty) return '';
    final account = getAccountById(accountId);
    return account?.name ?? '';
  }

  /// Add a new bank account
  Future<void> addAccount(BankAccount account, int userId) async {
    final isFirst = _accounts.isEmpty;
    final newAccount = isFirst ? account.copyWith(isDefault: true) : account;

    _accounts.add(newAccount);
    await _saveAccountsToBackend(userId);
  }

  /// Remove a bank account
  Future<void> removeAccount(String accountId, int userId) async {
    final removedAccount = _accounts.firstWhere((acc) => acc.id == accountId);
    final wasDefault = removedAccount.isDefault;
    _accounts.removeWhere((acc) => acc.id == accountId);

    if (wasDefault && _accounts.isNotEmpty) {
      _accounts[0] = _accounts[0].copyWith(isDefault: true);
    }

    await _saveAccountsToBackend(userId);
  }

  /// Set an account as the default
  Future<void> setDefaultAccount(String accountId, int userId) async {
    for (int i = 0; i < _accounts.length; i++) {
      _accounts[i] = _accounts[i].copyWith(
        isDefault: _accounts[i].id == accountId,
      );
    }
    await _saveAccountsToBackend(userId);
  }

  /// Save accounts to backend
  Future<void> _saveAccountsToBackend(int userId) async {
    await ExpenseSupabaseService.saveAccounts(_accounts, userId: userId);
  }

  /// Clear all data
  void clear() {
    _accounts.clear();
  }
}
