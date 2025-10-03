import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/expense_provider.dart';
import 'providers/user_provider.dart';
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/user_selector_screen.dart';
import 'services/sharing_intent_service.dart';
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
    try {
      final userId = context.read<UserProvider>().userId;
      if (userId.isNotEmpty) {
        final provider = context.read<ExpenseProvider>();
        await provider.initialize();
        await SharingIntentService.initialize();
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<UserProvider>().userId;
    if (userId.isEmpty) {
      return UserSelectorScreen(onUserSelected: () {
        setState(() {});
        _initializeApp();
      });
    }
    if (!_initialized) {
      return SplashScreen(
        onInit: () async {
          final provider = context.read<ExpenseProvider>();
          await provider.initialize();
          await SharingIntentService.initialize();
        },
        onReady: () {
          setState(() {
            _initialized = true;
          });
        },
      );
    }
    return const MainScreen();
  }
}
