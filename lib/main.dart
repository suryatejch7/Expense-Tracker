import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/expense_provider.dart';
import 'screens/main_screen.dart';
import 'services/sharing_intent_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ExpenseProvider(),
      child: MaterialApp(
        title: 'Expense Tracker',
        theme: ThemeData(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00D4FF),
            surface: Color(0xFF121212),
            surfaceContainer: Color(0xFF1E1E1E),
          ),
          scaffoldBackgroundColor: const Color(0xFF121212),
          cardColor: const Color(0xFF1E1E1E),
          useMaterial3: true,
        ),
        home: const ExpenseTrackerApp(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class ExpenseTrackerApp extends StatefulWidget {
  const ExpenseTrackerApp({super.key});

  @override
  State<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends State<ExpenseTrackerApp> {
  @override
  void initState() {
    super.initState();
    _initializeSharingIntent();
  }

  void _initializeSharingIntent() {
    // Initialize sharing intent listeners for OCR processing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SharingIntentService.initializeSharingListeners(context);
    });
  }

  @override
  void dispose() {
    SharingIntentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const MainScreen();
  }
}
