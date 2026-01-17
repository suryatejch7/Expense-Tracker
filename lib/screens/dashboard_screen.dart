import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_card.dart';
import '../widgets/category_summary.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Check data consistency and reload if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDataConsistency();
    });
  }

  @override
  void dispose() {
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
        provider.loadMoreExpenses();
      }
    }
  }

  Future<void> _checkDataConsistency() async {
    if (!mounted) return;
    
    final expenseProvider = context.read<ExpenseProvider>();
    
    // Check if data is consistent with backend
    final isConsistent = await expenseProvider.verifyDataConsistency();
    
    if (!isConsistent && mounted) {
      // Reload expenses from backend to fix inconsistency
      await expenseProvider.reloadExpenses();
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
              child: CategorySummary(),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Recent Expenses',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Consumer<ExpenseProvider>(
            builder: (context, expenseProvider, child) {
              final expenses = expenseProvider.filteredExpenses;

              if (expenses.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No expenses found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
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
                        key: ValueKey(expense.id),
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Total Spent',
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
                      final animatedValue = totalExpense * _numberAnimation.value;
                      return Text(
                        '₹${animatedValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isOverBudget ? Colors.red : Theme.of(context).colorScheme.primary,
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
                      '+₹${budgetExcess.toStringAsFixed(0)} over',
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
                    'Budget: ₹${monthlyBudget.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  if (!isOverBudget) ...[
                    Text(
                      '₹${(monthlyBudget - totalExpense).toStringAsFixed(0)} left',
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