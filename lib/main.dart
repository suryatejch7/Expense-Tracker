import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:io';
import 'dart:async';
import 'providers/expense_provider.dart';
import 'screens/main_screen.dart';
import 'screens/add_expense_screen.dart';
import 'services/ocr_processor.dart';

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
  StreamSubscription? _intentDataStreamSubscription;
  late ReceiveSharingIntent _receiveSharingIntent;
  late OCRProcessor _ocrProcessor;

  @override
  void initState() {
    super.initState();
    _receiveSharingIntent = ReceiveSharingIntent.instance;
    _ocrProcessor = OCRProcessor();
    _initSharingIntent();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    _ocrProcessor.dispose();
    super.dispose();
  }

  void _initSharingIntent() {
    // For files already shared when the app wasn't running
    _receiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _detectReceiptTypeAndProcess(value.first.path);
      }
    });

    // For files shared while the app is running
    _intentDataStreamSubscription =
        _receiveSharingIntent.getMediaStream().listen((List<SharedMediaFile> value) {
          if (value.isNotEmpty) {
            _detectReceiptTypeAndProcess(value.first.path);
          }
        });
  }

  /// Detect receipt type from the share intent and process the image
  void _detectReceiptTypeAndProcess(String imagePath) async {
    // Detect which activity alias was used by checking the current activity
    String receiptType = 'gpay_clean'; // Default

    try {
      // Try to get activity information to determine which share option was used
      // Since we can't easily get the exact activity alias from Flutter,
      // we'll use a simplified approach and let users choose if needed

      // For now, we'll try both types and see which one works better
      // In a full implementation, you'd use platform channels to get the intent metadata

      _processSharedImage(imagePath, receiptType);
    } catch (e) {
      debugPrint('Error detecting receipt type: $e');
      _processSharedImage(imagePath, 'gpay_clean');
    }
  }

  void _processSharedImage(String imagePath, String receiptType) async {
    File imageFile = File(imagePath);

    // Show processing dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          content: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Processing receipt...'),
            ],
          ),
        ),
      );
    }

    try {
      Map<String, dynamic> result = await _ocrProcessor.processImageWithManualType(
        imageFile,
        receiptType
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result['success'] && mounted) {
        Map<String, String> expenseData = Map<String, String>.from(result['expenseData'] ?? {});
        String extractedAmount = expenseData['amount'] ?? '';

        if (extractedAmount.isNotEmpty) {
          double? amount = double.tryParse(extractedAmount);
          if (amount != null) {
            // Navigate to Add Expense screen with pre-filled amount
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddExpenseScreen(
                  prefilledAmount: amount,
                ),
              ),
            );
            return;
          }
        }

        // If we get here, try the other receipt type as fallback
        if (receiptType == 'gpay_clean') {
          _processSharedImage(imagePath, 'googlepay');
          return;
        }
      }

      // If both attempts failed, show error and open empty add expense screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Could not extract amount from receipt. Please enter manually.')),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );

        // Still navigate to add expense screen for manual entry
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AddExpenseScreen(),
          ),
        );
      }

    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );

        // Navigate to add expense screen for manual entry
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AddExpenseScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MainScreen();
  }
}
