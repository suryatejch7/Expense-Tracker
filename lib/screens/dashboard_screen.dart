import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense_models.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_card.dart';
import '../widgets/income_card.dart';
import '../widgets/category_summary.dart';

enum RecentViewType { expenses, income, all }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  RecentViewType _selectedViewType = RecentViewType.expenses;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8;

    if (currentScroll >= threshold) {
      final provider = context.read<ExpenseProvider>();
      if (provider.hasMoreExpenses && !provider.isLoadingMore) {
        provider.loadMoreExpenses();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          final expenseProvider = context.read<ExpenseProvider>();
          await expenseProvider.reloadExpenses();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Expense Tracker',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        TotalExpenseWidget(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: IncomeSummaryWidget(),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CategorySummary(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildViewTypeSelector(),
              ),
            ),
            Consumer<ExpenseProvider>(
              builder: (context, expenseProvider, child) {
                return _buildTransactionsList(expenseProvider);
              },
            ),
            // Loading indicator for infinite scroll
            Consumer<ExpenseProvider>(
              builder: (context, provider, child) {
                if (provider.isLoadingMore) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  );
                }
                if (!provider.hasMoreExpenses && provider.expenses.isNotEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'No more expenses',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    ),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildViewTypeSelector() {
    return Row(
      children: [
        PopupMenuButton<RecentViewType>(
          onSelected: (value) {
            setState(() {
              _selectedViewType = value;
            });
          },
          offset: const Offset(0, 40),
          color: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getViewTypeLabel(_selectedViewType),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey[400],
                size: 28,
              ),
            ],
          ),
          itemBuilder: (context) => [
            _buildPopupMenuItem(
              RecentViewType.expenses,
              'Recent Expenses',
              Icons.arrow_upward_rounded,
            ),
            _buildPopupMenuItem(
              RecentViewType.income,
              'Recent Income',
              Icons.arrow_downward_rounded,
            ),
            _buildPopupMenuItem(
              RecentViewType.all,
              'Recent Activity',
              Icons.swap_vert_rounded,
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }

  PopupMenuItem<RecentViewType> _buildPopupMenuItem(
    RecentViewType type,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedViewType == type;
    return PopupMenuItem<RecentViewType>(
      value: type,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected
                ? (type == RecentViewType.income
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary)
                : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[300],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(
              Icons.check,
              color: type == RecentViewType.income
                  ? Colors.green
                  : Theme.of(context).colorScheme.primary,
              size: 18,
            ),
          ],
        ],
      ),
    );
  }

  String _getViewTypeLabel(RecentViewType type) {
    switch (type) {
      case RecentViewType.expenses:
        return 'Recent Expenses';
      case RecentViewType.income:
        return 'Recent Income';
      case RecentViewType.all:
        return 'Recent Activity';
    }
  }

  /// Build the transactions list based on selected view type
  Widget _buildTransactionsList(ExpenseProvider provider) {
    switch (_selectedViewType) {
      case RecentViewType.expenses:
        return _buildExpensesList(provider);
      case RecentViewType.income:
        return _buildIncomesList(provider);
      case RecentViewType.all:
        return _buildAllTransactionsList(provider);
    }
  }

  Widget _buildExpensesList(ExpenseProvider provider) {
    final expenses = provider.expenses;

    if (expenses.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 80,
                color: Colors.grey[700],
              ),
              const SizedBox(height: 16),
              const Text(
                'No expenses found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add your first expense by tapping the + button',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final currency = provider.currency;
    final categories = provider.categories;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final expense = expenses[index];
          final category = _findCategory(categories, expense.category);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ExpenseCard(
              key: ValueKey('expense_${expense.id}'),
              expense: expense,
              currency: currency,
              category: category,
              index: index,
            ),
          );
        },
        childCount: expenses.length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
      ),
    );
  }

  Widget _buildIncomesList(ExpenseProvider provider) {
    final incomes = provider.incomes;

    if (incomes.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 80,
                color: Colors.grey[700],
              ),
              const SizedBox(height: 16),
              const Text(
                'No income recorded',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add income by tapping the + button',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final currency = provider.currency;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final income = incomes[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: IncomeCard(
              key: ValueKey('income_${income.id}'),
              income: income,
              currency: currency,
              index: index,
            ),
          );
        },
        childCount: incomes.length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
      ),
    );
  }

  Widget _buildAllTransactionsList(ExpenseProvider provider) {
    final expenses = provider.expenses;
    final incomes = provider.incomes;

    // Combine and sort by date (most recent first)
    final List<dynamic> allTransactions = [
      ...expenses.map((e) => {'type': 'expense', 'data': e, 'date': e.date}),
      ...incomes.map((i) => {'type': 'income', 'data': i, 'date': i.date}),
    ];
    allTransactions.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );

    if (allTransactions.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swap_vert_rounded, size: 80, color: Colors.grey[700]),
              const SizedBox(height: 16),
              const Text(
                'No transactions yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add expenses or income by tapping the + button',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final currency = provider.currency;
    final categories = provider.categories;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final transaction = allTransactions[index];
          final isExpense = transaction['type'] == 'expense';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: isExpense
                ? ExpenseCard(
                    key: ValueKey('expense_${transaction['data'].id}'),
                    expense: transaction['data'],
                    currency: currency,
                    category: _findCategory(
                      categories,
                      (transaction['data'] as Expense).category,
                    ),
                    index: index,
                  )
                : IncomeCard(
                    key: ValueKey('income_${transaction['data'].id}'),
                    income: transaction['data'],
                    currency: currency,
                    index: index,
                  ),
          );
        },
        childCount: allTransactions.length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
      ),
    );
  }


  ExpenseCategory _findCategory(
    List<ExpenseCategory> categories,
    String categoryName,
  ) {
    for (final cat in categories) {
      if (cat.name == categoryName) return cat;
    }
    return ExpenseCategory(
      id: categoryName,
      name: categoryName,
      icon: '📦',
      colorHex: '#747D8C',
    );
  }
}

class TotalExpenseWidget extends StatefulWidget {
  const TotalExpenseWidget({super.key});

  @override
  State<TotalExpenseWidget> createState() => _TotalExpenseWidgetState();
}

class _TotalExpenseWidgetState extends State<TotalExpenseWidget>
    with TickerProviderStateMixin {
  late AnimationController _numberController;
  late AnimationController _progressController;

  late Animation<double> _numberAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _numberController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _numberAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _numberController, curve: Curves.easeOutCubic),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    // Start animations with a slight delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _numberController.forward();
        _progressController.forward();
      }
    });
  }

  @override
  void dispose() {
    _numberController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        final isOverBudget = expenseProvider.isOverBudget;
        final budgetExcess = expenseProvider.budgetExcess;
        final monthlyBudget = expenseProvider.monthlyBudget;
        final totalExpense = expenseProvider.currentMonthTotalExpense;
        final currency = expenseProvider.currency;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'This Month\'s Spending',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _numberAnimation,
                    builder: (context, child) {
                      final animatedValue =
                          totalExpense * _numberAnimation.value;
                      return Text(
                        '$currency${animatedValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isOverBudget
                              ? Colors.red
                              : Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ),
                if (isOverBudget) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+$currency${budgetExcess.toStringAsFixed(0)} over',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (monthlyBudget > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Budget: $currency${monthlyBudget.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  if (!isOverBudget) ...[
                    Text(
                      '$currency${(monthlyBudget - totalExpense).toStringAsFixed(0)} left',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    final progressValue =
                        (totalExpense / monthlyBudget).clamp(0.0, 1.0) *
                        _progressAnimation.value;
                    return LinearProgressIndicator(
                      value: progressValue,
                      backgroundColor: Colors.grey.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOverBudget
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Widget to show income and net balance summary
class IncomeSummaryWidget extends StatelessWidget {
  const IncomeSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        final currency = expenseProvider.currency;
        final totalIncome = expenseProvider.totalIncomeThisMonth;
        final totalExpense = expenseProvider.currentMonthTotalExpense;
        final netBalance = totalIncome - totalExpense;
        final isPositive = netBalance >= 0;

        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Income section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_downward_rounded,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Income',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+$currency${totalIncome.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(
                height: 40,
                width: 1,
                color: Colors.grey.withValues(alpha: 0.3),
              ),
              // Net Balance section (center)
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.swap_vert_rounded,
                          color: isPositive ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Net',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isPositive ? '+' : '-'}$currency${netBalance.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(
                height: 40,
                width: 1,
                color: Colors.grey.withValues(alpha: 0.3),
              ),
              // Total Spent section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Spent',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '-$currency${totalExpense.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
