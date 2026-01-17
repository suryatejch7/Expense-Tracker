import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/expense_provider.dart';
import 'providers/user_provider.dart';
import 'screens/main_screen.dart';
import 'screens/register_user_screen.dart';
import 'services/supabase_init_service.dart';
import 'services/notification_service.dart';
import 'services/cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseInitService.initialize();
  
  // Initialize Cache Service
  await CacheService.init();
  
  // Initialize Notifications
  await NotificationService.initialize();

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
            surface: Colors.black,
            surfaceContainer: Color(0xFF0D0D0D),
          ),
          scaffoldBackgroundColor: Colors.black,
          cardColor: const Color(0xFF0D0D0D),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// AuthWrapper handles authentication state
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Load user from storage
    final userProvider = context.read<UserProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    await userProvider.loadUserFromStorage();
    
    // Initialize expense provider if user is logged in
    if (userProvider.isLoggedIn) {
      await userProvider.initializeExpenseProvider(expenseProvider);
    }
    
    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
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

    // Use Selector to monitor only isLoggedIn boolean
    return Selector<UserProvider, bool>(
      selector: (_, userProvider) => userProvider.isLoggedIn,
      builder: (context, isLoggedIn, child) {
        if (isLoggedIn) {
          return const MainScreen();
        } else {
          return RegisterUserScreen(
            onRegistered: () async {
              final userProvider = context.read<UserProvider>();
              
              // Initialize expense provider when user is registered
              if (userProvider.isLoggedIn) {
                await userProvider.initializeExpenseProvider(context.read<ExpenseProvider>());
              }
              
              // Let the Selector handle the rebuild automatically when isLoggedIn changes
            },
          );
        }
      },
    );
  }
}