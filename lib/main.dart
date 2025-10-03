import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/expense_provider.dart';
import 'providers/user_provider.dart';
import 'screens/main_screen.dart';
import 'screens/user_selector_screen.dart';
import 'services/supabase_init_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseInitService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
      ],
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
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Load user from storage
    await context.read<UserProvider>().loadUserFromStorage();
    
    // Initialize expense provider if user is logged in
    final userProvider = context.read<UserProvider>();
    if (userProvider.isLoggedIn) {
      await userProvider.initializeExpenseProvider(context.read<ExpenseProvider>());
    }
    
    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoggedIn) {
          return const MainScreen();
        } else {
          return UserSelectorScreen(
            onUserSelected: () async {
              // Initialize expense provider when user is selected
              if (userProvider.isLoggedIn) {
                await userProvider.initializeExpenseProvider(context.read<ExpenseProvider>());
              }
              // The Consumer will automatically rebuild when userProvider.notifyListeners() is called
            },
          );
        }
      },
    );
  }
}
