import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'categories_screen.dart';
import 'add_expense_screen.dart';
import 'transaction_scanner_screen.dart';
import '../services/sharing_intent_service.dart';
import '../widgets/liquid_glass_nav_bar.dart';


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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF121212),
                  Color(0xFF1E1E1E),
                ],
              ),
            ),
          ),
          // Main content without bottom padding
          _screens[_currentIndex],
          // Glass navigation bar positioned at bottom
          GlassNavBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ],
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: Duration.zero, // No animation
        child: GestureDetector(
          key: const ValueKey('fab_gesture'),
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
            key: const ValueKey('main_fab'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            onPressed: null, // Disable default onPressed
            child: const Icon(Icons.add, color: Colors.black),
          ),
        ),
      ),
      floatingActionButtonLocation: _CustomFABLocation(),
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
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
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
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
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

class _CustomFABLocation extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Standard FAB position: 16px from right edge, 16px from bottom
    // But we need to account for the custom navigation bar (70px height + 30px bottom margin = 100px)
    final double right = 16.0;
    final double bottom = 16.0 + 100.0; // 16px standard + 100px for custom nav bar
    
    return Offset(
      scaffoldGeometry.scaffoldSize.width - right - scaffoldGeometry.floatingActionButtonSize.width,
      scaffoldGeometry.scaffoldSize.height - bottom - scaffoldGeometry.floatingActionButtonSize.height,
    );
  }

  @override
  String toString() => 'FloatingActionButtonLocation.endFloat';
}
