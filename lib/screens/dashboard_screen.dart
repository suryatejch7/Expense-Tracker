import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_card.dart';
import '../widgets/income_card.dart';
import '../widgets/category_summary.dart';

/// Performance logging helper
class _PerfLog {
  static final Stopwatch _stopwatch = Stopwatch();
  static DateTime? _lastTimestamp;
  
  static void log(String message) {
    final now = DateTime.now();
    final elapsed = _lastTimestamp != null 
        ? now.difference(_lastTimestamp!).inMilliseconds 
        : 0;
    _lastTimestamp = now;
    debugPrint('[DASHBOARD ${now.toString().substring(11, 23)}] (+${elapsed}ms) $message');
  }
  
  static void startTimer(String label) {
    _stopwatch.reset();
    _stopwatch.start();
    log('⏱️ START: $label');
  }
  
  static void endTimer(String label) {
    _stopwatch.stop();
    log('⏱️ END: $label - took ${_stopwatch.elapsedMilliseconds}ms');
  }
}

/// View type for the recent transactions list
enum RecentViewType {
  expenses,
  income,
  all,
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  RecentViewType _selectedViewType = RecentViewType.expenses;
  int _buildCount = 0;

  @override
  void initState() {
    _PerfLog.log('🚀 initState() called');
    super.initState();
    _scrollController.addListener(_onScroll);
    // Check data consistency and reload if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _PerfLog.log('📋 postFrameCallback executing');
      _checkDataConsistency();
    });
    _PerfLog.log('✅ initState() complete');
  }

  @override
  void dispose() {
    _PerfLog.log('🗑️ dispose() called - total builds: $_buildCount');
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Infinite scroll listener - loads more when near bottom
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8; // Load more at 80% scroll
    
    if (currentScroll >= threshold) {
      final provider = context.read<ExpenseProvider>();
      if (provider.hasMoreExpenses && !provider.isLoadingMore) {
        _PerfLog.log('📜 Loading more expenses (infinite scroll triggered)');
        provider.loadMoreExpenses();
      }
    }
  }

  Future<void> _checkDataConsistency() async {
    _PerfLog.startTimer('Data consistency check');
    if (!mounted) return;
    
    final expenseProvider = context.read<ExpenseProvider>();
    
    // Check if data is consistent with backend
    final isConsistent = await expenseProvider.verifyDataConsistency();
    _PerfLog.log('📊 Data consistency result: $isConsistent');
    
    if (!isConsistent && mounted) {
      _PerfLog.log('⚠️ Data inconsistent, reloading from backend...');
      await expenseProvider.reloadExpenses();
      _PerfLog.log('✅ Data reloaded');
    }
    _PerfLog.endTimer('Data consistency check');
  }

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    _PerfLog.log('🔨 build() #$_buildCount called');
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          _PerfLog.startTimer('Pull-to-refresh');
          final expenseProvider = context.read<ExpenseProvider>();
          await expenseProvider.reloadExpenses();
          _PerfLog.endTimer('Pull-to-refresh');
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
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
        ),
      ),
    );
  }

  /// Build the view type selector dropdown
  Widget _buildViewTypeSelector() {
    _PerfLog.log('🔧 Building view type selector (current: $_selectedViewType)');
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
            _buildPopupMenuItem(RecentViewType.expenses, 'Recent Expenses', Icons.arrow_upward_rounded),
            _buildPopupMenuItem(RecentViewType.income, 'Recent Income', Icons.arrow_downward_rounded),
            _buildPopupMenuItem(RecentViewType.all, 'Recent Activity', Icons.swap_vert_rounded),
          ],
        ),
        const Spacer(),
      ],
    );
  }

  PopupMenuItem<RecentViewType> _buildPopupMenuItem(RecentViewType type, String label, IconData icon) {
    final isSelected = _selectedViewType == type;
    return PopupMenuItem<RecentViewType>(
      value: type,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected 
                ? (type == RecentViewType.income ? Colors.green : Theme.of(context).colorScheme.primary)
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
              color: type == RecentViewType.income ? Colors.green : Theme.of(context).colorScheme.primary,
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
    _PerfLog.log('📋 Building transactions list for: $_selectedViewType');
    _PerfLog.log('   - Expenses count: ${provider.filteredExpenses.length}');
    _PerfLog.log('   - Incomes count: ${provider.filteredIncomes.length}');
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
    final expenses = provider.filteredExpenses;

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
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add your first expense by tapping the + button',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final expense = expenses[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ExpenseCard(
              key: ValueKey('expense_${expense.id}'),
              expense: expense,
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
    final incomes = provider.filteredIncomes;

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
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add income by tapping the + button',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final income = incomes[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: IncomeCard(
              key: ValueKey('income_${income.id}'),
              income: income,
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
    final expenses = provider.filteredExpenses;
    final incomes = provider.filteredIncomes;

    // Combine and sort by date (most recent first)
    final List<dynamic> allTransactions = [
      ...expenses.map((e) => {'type': 'expense', 'data': e, 'date': e.date}),
      ...incomes.map((i) => {'type': 'income', 'data': i, 'date': i.date}),
    ];
    allTransactions.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    if (allTransactions.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.swap_vert_rounded,
                size: 80,
                color: Colors.grey[700],
              ),
              const SizedBox(height: 16),
              const Text(
                'No transactions yet',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add expenses or income by tapping the + button',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

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
                    index: index,
                  )
                : IncomeCard(
                    key: ValueKey('income_${transaction['data'].id}'),
                    income: transaction['data'],
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
}

class TotalExpenseWidget extends StatefulWidget {
  const TotalExpenseWidget({super.key});
  
  // Static flag to ensure animation only runs once per app session
  static bool _hasAnimated = false;
  static void resetAnimation() => _hasAnimated = false;

  @override
  State<TotalExpenseWidget> createState() => _TotalExpenseWidgetState();
}

class _TotalExpenseWidgetState extends State<TotalExpenseWidget>
    with TickerProviderStateMixin {
  late AnimationController _numberController;
  late AnimationController _progressController;
  
  late Animation<double> _numberAnimation;
  late Animation<double> _progressAnimation;
  
  bool _shouldAnimate = false;

  @override
  void initState() {
    super.initState();
    // Only animate if we haven't animated yet this session
    _shouldAnimate = !TotalExpenseWidget._hasAnimated;
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _numberController = AnimationController(
      duration: const Duration(milliseconds: 600), // Reduced from 1500ms
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800), // Reduced from 2000ms
      vsync: this,
    );

    _numberAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _numberController,
      curve: Curves.easeOutCubic,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOut,
    ));

    if (_shouldAnimate) {
      // Start animations with a slight delay, only once per session
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          TotalExpenseWidget._hasAnimated = true;
          _numberController.forward();
          _progressController.forward();
        }
      });
    } else {
      // Skip animation, set to completed state immediately
      _numberController.value = 1.0;
      _progressController.value = 1.0;
    }
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
        final totalIncome = expenseProvider.totalIncomeThisMonth;
        final netBalance = totalIncome - totalExpense;
        final isPositive = netBalance >= 0;
        final currency = expenseProvider.currency;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Net Expense',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
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
                      final animatedValue = netBalance * _numberAnimation.value;
                      return Text(
                        '${isPositive ? '+' : ''}$currency${animatedValue.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green : (isOverBudget ? Colors.red : Theme.of(context).colorScheme.primary),
                        ),
                      );
                    },
                  ),
                ),
                if (isOverBudget) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
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
                    final progressValue = (totalExpense / monthlyBudget).clamp(0.0, 1.0) * _progressAnimation.value;
                    return LinearProgressIndicator(
                      value: progressValue,
                      backgroundColor: Colors.grey.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOverBudget ? Colors.red : Theme.of(context).colorScheme.primary,
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
              // Total Spent section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Spent',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currency${totalExpense.toStringAsFixed(2)}',
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