import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard_screen.dart';
import 'categories_screen.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';
import 'transaction_scanner_screen.dart';
import '../services/sharing_intent_service.dart';
import '../widgets/liquid_glass_nav_bar.dart';
import '../widgets/expandable_fab.dart';
import '../providers/expense_provider.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const CategoriesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Set the context for sharing service after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SharingIntentService.setContext(context);
      _checkDataConsistency();
    });
  }

  Future<void> _checkDataConsistency() async {
    if (!mounted) return;
    
    // Import ExpenseProvider to check data consistency
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
      extendBody: true,
      body: Stack(
        children: [
          // Background - pitch black
          Container(
            color: Colors.black,
          ),
          // Main content without bottom padding
          _screens[_currentIndex],
          // Glass navigation bar positioned at bottom
          GlassNavBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              // Only update if tapping a different tab
              if (index != _currentIndex) {
                setState(() {
                  _currentIndex = index;
                });
              }
            },
          ),
          // Expandable FAB for Add Expense/Income
          if (_currentIndex == 0)
            Positioned(
              right: 16,
              bottom: 120, // Position above the nav bar
              child: ExpandableFab(
                onAddExpense: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddExpenseScreen(),
                    ),
                  );
                },
                onAddIncome: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddIncomeScreen(),
                    ),
                  );
                },
                onScanReceipt: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TransactionScannerScreen(),
                    ),
                  );
                },
              ),
            ),
        ],
      )
    );
  }
}
