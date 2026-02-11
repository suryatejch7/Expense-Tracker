import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/expense_models.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_card.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  FilterPeriod _selectedPeriod = FilterPeriod.monthly;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String? _selectedAccountId; // null means all accounts

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case FilterPeriod.weekly:
        return 'This Week';
      case FilterPeriod.monthly:
        return 'This Month';
      case FilterPeriod.yearly:
        return 'This Year';
      case FilterPeriod.allTime:
        return 'All Time';
      case FilterPeriod.custom:
        if (_customStartDate != null && _customEndDate != null) {
          final format = DateFormat('MMM d');
          return '${format.format(_customStartDate!)} - ${format.format(_customEndDate!)}';
        }
        return 'Custom Range';
    }
  }

  String _getFilterSummary(ExpenseProvider provider) {
    String periodLabel = _getPeriodLabel();
    if (_selectedAccountId != null) {
      final account = provider.getAccountById(_selectedAccountId!);
      if (account != null) {
        return '$periodLabel • ${account.name}';
      }
    }
    return periodLabel;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FilterBottomSheet(
        currentPeriod: _selectedPeriod,
        customStartDate: _customStartDate,
        customEndDate: _customEndDate,
        currentAccountId: _selectedAccountId,
        onFilterSelected: (period, startDate, endDate, accountId) {
          setState(() {
            _selectedPeriod = period;
            _customStartDate = startDate;
            _customEndDate = endDate;
            _selectedAccountId = accountId;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          // Filter chip showing current selection
          Consumer<ExpenseProvider>(
            builder: (context, provider, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  avatar: const Icon(Icons.filter_list, size: 18),
                  label: Text(
                    _getFilterSummary(provider),
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: _showFilterSheet,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, expenseProvider, child) {
          final categoryTotals = expenseProvider.getCategoryTotalsByPeriod(
            _selectedPeriod,
            customStart: _customStartDate,
            customEnd: _customEndDate,
            accountId: _selectedAccountId,
          );
          final totalForPeriod = expenseProvider.getTotalByPeriod(
            _selectedPeriod,
            customStart: _customStartDate,
            customEnd: _customEndDate,
            accountId: _selectedAccountId,
          );

          if (categoryTotals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.category_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No expenses for ${_getPeriodLabel().toLowerCase()}',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add some expenses to see category breakdown',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return Column(
            children: [
              // Period summary header
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getFilterSummary(expenseProvider),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${totalForPeriod.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${sortedCategories.length} categories',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${expenseProvider.getExpensesByPeriodType(_selectedPeriod, customStart: _customStartDate, customEnd: _customEndDate, accountId: _selectedAccountId).length} expenses',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Categories list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sortedCategories.length,
                  itemBuilder: (context, index) {
                    final entry = sortedCategories[index];
                    final categoryName = entry.key;
                    final amount = entry.value;
                    final percentage = totalForPeriod > 0
                        ? (amount / totalForPeriod * 100)
                        : 0.0;

                    // Find the category object
                    final category = expenseProvider.categories.firstWhere(
                      (cat) => cat.name == categoryName,
                      orElse: () => ExpenseCategory(
                        id: categoryName,
                        name: categoryName,
                        icon: '📦',
                        colorHex: '#747D8C',
                      ),
                    );

                    // Budget logic (budgets are monthly, so only show for monthly view)
                    final budget = _selectedPeriod == FilterPeriod.monthly
                        ? expenseProvider.getCategoryBudget(categoryName)
                        : 0.0;
                    final isOverBudget =
                        _selectedPeriod == FilterPeriod.monthly &&
                        budget > 0 &&
                        amount > budget;
                    final budgetExcess = amount - budget;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CategoryDetailScreen(
                                categoryName: categoryName,
                                filterPeriod: _selectedPeriod,
                                customStartDate: _customStartDate,
                                customEndDate: _customEndDate,
                                accountId: _selectedAccountId,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: isOverBudget
                                ? Border.all(color: Colors.red, width: 2)
                                : null,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: isOverBudget
                                            ? Colors.red.withValues(alpha: 0.2)
                                            : category.color.withValues(
                                                alpha: 0.2,
                                              ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                        child: Text(
                                          category.icon,
                                          style: TextStyle(
                                            fontSize: 28,
                                            color: isOverBudget
                                                ? Colors.red
                                                : category.color,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                category.displayName,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: isOverBudget
                                                      ? Colors.red
                                                      : Colors.white,
                                                ),
                                              ),
                                              if (isOverBudget) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: const Text(
                                                    'OVER',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '₹${amount.toStringAsFixed(2)} • ${percentage.toStringAsFixed(1)}%',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          if (budget > 0 &&
                                              _selectedPeriod ==
                                                  FilterPeriod.monthly) ...[
                                            const SizedBox(height: 8),
                                            LinearProgressIndicator(
                                              value: (amount / budget).clamp(
                                                0.0,
                                                1.0,
                                              ),
                                              backgroundColor: Colors.grey
                                                  .withValues(alpha: 0.3),
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    isOverBudget
                                                        ? Colors.red
                                                        : category.color,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Budget: ₹${budget.toStringAsFixed(0)}${isOverBudget ? ' (Over by ₹${budgetExcess.toStringAsFixed(0)})' : ''}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isOverBudget
                                                    ? Colors.red
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹${amount.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: isOverBudget
                                                ? Colors.red
                                                : Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${expenseProvider.getExpensesByCategoryAndPeriod(categoryName, _selectedPeriod, customStart: _customStartDate, customEnd: _customEndDate).length} items',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Bottom padding for nav bar
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }
}

// Filter Bottom Sheet Widget
class _FilterBottomSheet extends StatefulWidget {
  final FilterPeriod currentPeriod;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final String? currentAccountId;
  final Function(FilterPeriod, DateTime?, DateTime?, String?) onFilterSelected;

  const _FilterBottomSheet({
    required this.currentPeriod,
    required this.customStartDate,
    required this.customEndDate,
    required this.currentAccountId,
    required this.onFilterSelected,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late FilterPeriod _selectedPeriod;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.currentPeriod;
    _startDate = widget.customStartDate;
    _endDate = widget.customEndDate;
    _selectedAccountId = widget.currentAccountId;
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.black,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = FilterPeriod.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Filter by Period',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildFilterOption(
              FilterPeriod.weekly,
              'This Week',
              Icons.view_week,
            ),
            _buildFilterOption(
              FilterPeriod.monthly,
              'This Month',
              Icons.calendar_month,
            ),
            _buildFilterOption(
              FilterPeriod.yearly,
              'This Year',
              Icons.calendar_today,
            ),
            _buildFilterOption(
              FilterPeriod.allTime,
              'All Time',
              Icons.all_inclusive,
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedPeriod == FilterPeriod.custom
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.date_range,
                  color: _selectedPeriod == FilterPeriod.custom
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
              ),
              title: const Text('Custom Date Range'),
              subtitle: _startDate != null && _endDate != null
                  ? Text(
                      '${DateFormat('MMM d, yyyy').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : const Text('Select a date range'),
              trailing: _selectedPeriod == FilterPeriod.custom
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: _selectDateRange,
            ),
            const SizedBox(height: 20),
            const Text(
              'Filter by Account',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<ExpenseProvider>(
              builder: (context, provider, _) {
                final accounts = provider.accounts;
                return Column(
                  children: [
                    _buildAccountOption(
                      null,
                      'All Accounts',
                      Icons.account_balance_wallet,
                    ),
                    ...accounts.map(
                      (account) => _buildAccountOption(
                        account.id,
                        account.name,
                        Icons.account_balance,
                      ),
                    ),
                  ],
                );
              },
            ),
            const Divider(color: Colors.grey),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onFilterSelected(
                    _selectedPeriod,
                    _startDate,
                    _endDate,
                    _selectedAccountId,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply Filter',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountOption(String? accountId, String title, IconData icon) {
    final isSelected = _selectedAccountId == accountId;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
        ),
      ),
      title: Text(title),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () {
        setState(() {
          _selectedAccountId = accountId;
        });
      },
    );
  }

  Widget _buildFilterOption(FilterPeriod period, String title, IconData icon) {
    final isSelected = _selectedPeriod == period;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
        ),
      ),
      title: Text(title),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
    );
  }
}

class CategoryDetailScreen extends StatelessWidget {
  final String categoryName;
  final FilterPeriod filterPeriod;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final String? accountId;

  const CategoryDetailScreen({
    super.key,
    required this.categoryName,
    this.filterPeriod = FilterPeriod.monthly,
    this.customStartDate,
    this.customEndDate,
    this.accountId,
  });

  String _getPeriodLabel() {
    switch (filterPeriod) {
      case FilterPeriod.weekly:
        return 'This Week';
      case FilterPeriod.monthly:
        return 'This Month';
      case FilterPeriod.yearly:
        return 'This Year';
      case FilterPeriod.allTime:
        return 'All Time';
      case FilterPeriod.custom:
        if (customStartDate != null && customEndDate != null) {
          final format = DateFormat('MMM d');
          return '${format.format(customStartDate!)} - ${format.format(customEndDate!)}';
        }
        return 'Custom Range';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        // Find the category object
        final category = expenseProvider.categories.firstWhere(
          (cat) => cat.name == categoryName,
          orElse: () => ExpenseCategory(
            id: categoryName,
            name: categoryName,
            icon: '📦',
            colorHex: '#747D8C',
          ),
        );

        final expenses = expenseProvider.getExpensesByCategoryAndPeriod(
          categoryName,
          filterPeriod,
          customStart: customStartDate,
          customEnd: customEndDate,
          accountId: accountId,
        );
        final totalAmount = expenses.fold(
          0.0,
          (sum, expense) => sum + expense.amount,
        );

        // Get account name for display if filtered
        String? accountName;
        if (accountId != null) {
          final account = expenseProvider.getAccountById(accountId!);
          accountName = account?.name;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(category.displayName),
            backgroundColor: category.color.withValues(alpha: 0.1),
          ),
          body: expenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category.icon,
                        style: TextStyle(
                          fontSize: 80,
                          color: category.color.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No ${category.displayName.toLowerCase()} expenses',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'for ${_getPeriodLabel().toLowerCase()}${accountName != null ? ' ($accountName)' : ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: category.color.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            category.icon,
                            style: TextStyle(
                              fontSize: 48,
                              color: category.color,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '₹${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: category.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${expenses.length} expense${expenses.length == 1 ? '' : 's'} • ${_getPeriodLabel()}${accountName != null ? ' • $accountName' : ''}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ExpenseCard(
                              expense: expenses[index],
                              currency: expenseProvider.currency,
                              category: category,
                              index: index,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
