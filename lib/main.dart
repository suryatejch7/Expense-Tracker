import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/expense_provider.dart';
import 'providers/user_provider.dart';
import 'screens/main_screen.dart';
import 'services/supabase_service.dart';
import 'services/backup_service.dart';
import 'services/notification_service.dart';
import 'services/cache_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Storage
  await ExpenseSupabaseService.initialize();

  // Restore from auto-backup file if SharedPreferences was wiped
  await BackupService.restoreFromAutoBackupIfNeeded();

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
        theme: AppTheme.darkTheme,
        home: const AppBootstrap(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Silently ensures a local user exists, then shows MainScreen.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final userProvider = context.read<UserProvider>();
    final expenseProvider = context.read<ExpenseProvider>();

    // Try to load existing user
    await userProvider.loadUserFromStorage();

    // If no user exists, create a default local user automatically
    if (!userProvider.isLoggedIn) {
      await userProvider.registerUser('LocalUser');
    }

    // Initialize expense provider with the user
    if (userProvider.isLoggedIn) {
      await userProvider.initializeExpenseProvider(expenseProvider);
    }

    if (mounted) {
      setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    return const MainScreen();
  }
}
