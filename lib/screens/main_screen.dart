import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard_screen.dart';
import 'categories_screen.dart';
import 'add_expense_screen.dart';
import 'transaction_scanner_screen.dart';
import '../services/sharing_intent_service.dart';
import '../widgets/liquid_glass_nav_bar.dart';
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
          // FAB positioned manually in Stack to avoid Scaffold's FAB animation
          if (_currentIndex == 0)
            Positioned(
              right: 16,
              bottom: 120, // Position above the nav bar
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddExpenseScreen(),
                    ),
                  );
                },
                onLongPress: () {
                  _showAddExpenseOptions();
                },
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                    // Swipe up detected - navigate to TransactionScannerScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TransactionScannerScreen(),
                      ),
                    );
                  }
                },
                child: FloatingActionButton(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  onPressed: null, // Disable default onPressed
                  child: const Icon(Icons.add, color: Colors.black),
                ),
              ),
            ),
        ],
      )
    );
  }

  void _showAddExpenseOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Expense',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.edit,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: const Text('Manual Entry'),
              subtitle: const Text('Enter expense details manually'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddExpenseScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: const Text('Scan Receipt'),
              subtitle: const Text('Scan transaction screenshot'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransactionScannerScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
