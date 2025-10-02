import 'dart:io';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../services/ocr_processor.dart';
import '../screens/add_expense_screen.dart';

class SharedImageHandler {
  static final OCRProcessor _ocrProcessor = OCRProcessor();

  /// Handle shared image with receipt type detection
  static Future<void> handleSharedImage(BuildContext context, File imageFile, String? receiptType) async {
    if (!context.mounted) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Processing receipt...'),
            ],
          ),
        ),
      );

      // Determine receipt type from intent or default
      String processType = receiptType ?? 'gpay_clean';

      // Process image with OCR
      Map<String, dynamic> result = await _ocrProcessor.processImageWithManualType(imageFile, processType);

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (result['success'] == true) {
        Map<String, String> expenseData = result['expenseData'];
        String? extractedAmount = expenseData['amount'];

        if (extractedAmount != null && extractedAmount.isNotEmpty) {
          double? amount = double.tryParse(extractedAmount);
          if (amount != null && context.mounted) {
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
      }

      // If OCR failed or no amount found, show error and open empty add expense screen
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Could not extract amount from receipt. Please enter manually.')),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
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
      if (context.mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Initialize shared image listening
  static void initializeSharedImageHandling(BuildContext context) {
    // Handle app launch from shared image
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty && context.mounted) {
        _processSharedMedia(context, value);
      }
    });

    // Handle shared images while app is running
    ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty && context.mounted) {
        _processSharedMedia(context, value);
      }
    });
  }

  /// Process shared media files
  static void _processSharedMedia(BuildContext context, List<SharedMediaFile> sharedFiles) {
    for (SharedMediaFile file in sharedFiles) {
      if (file.type == SharedMediaType.image && file.path.isNotEmpty) {
        File imageFile = File(file.path);

        // Try to get receipt type from Android intent metadata
        // This would be set by the activity alias
        String? receiptType = _getReceiptTypeFromContext();

        handleSharedImage(context, imageFile, receiptType);
        break; // Process only the first image
      }
    }
  }

  /// Get receipt type from Android intent (simplified version)
  /// In a real implementation, this would get the receipt_type metadata
  /// from the Android intent that launched the app
  static String? _getReceiptTypeFromContext() {
    // This is a simplified version. In a full implementation,
    // you would need to use platform channels to get the intent metadata
    // For now, we'll default to null and let the handler decide
    return null;
  }

  /// Dispose resources
  static void dispose() {
    _ocrProcessor.dispose();
  }
}
