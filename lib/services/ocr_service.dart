import 'package:flutter/foundation.dart';
import '../models/receipt_types.dart';

class OCRService {

  // Amount extraction templates - UPDATED FOR PRECISE MANUAL SELECTION
  static final List<AmountTemplate> _amountTemplates = [
    // Google Pay Detailed Layout (pasted_image_3.png) - Focus above yellow line
    AmountTemplate(
      type: ReceiptType.googlePayDetailed,
      name: 'Google Pay Detailed',
      identifierPattern: RegExp(r'manual_googlepay', caseSensitive: false),
      cropBounds: {
        'left': 0.0,
        'top': 0.1,    // Start from just above the merchant circle
        'right': 1.0,
        'bottom': 0.5, // Crop exactly at yellow line - nothing below it
      },
      amountPatterns: [
        RegExp(r'₹(\d+(?:\.\d{2})?)'),                // ₹1 format
        RegExp(r'(?<!\d)(\d+)(?!\d)'),                // Standalone numbers
        RegExp(r'(\d+)(?=\s*$)', multiLine: true),    // Number at end of line
      ],
    ),

    // Google Pay Clean Layout - Large amount display (original working one)
    AmountTemplate(
      type: ReceiptType.googlePayClean,
      name: 'GPay Clean',
      identifierPattern: RegExp(r'manual_gpay_clean', caseSensitive: false),
      cropBounds: {
        'left': 0.05,
        'top': 0.25,    // Skip top area
        'right': 0.95,
        'bottom': 0.80, // Focus on main content area
      },
      amountPatterns: [
        RegExp(r'₹(\d+(?:\.\d{2})?)'),          // ₹1.00 format
        RegExp(r'(?<!\d)(\d+\.\d{2})(?!\d)'),   // Standalone 1.00
        RegExp(r'(?<!\d)(\d+)(?!\d)'),          // Standalone whole numbers
      ],
    ),
  ];

  /// Get template for manual receipt type selection
  static AmountTemplate getTemplateForManualType(String manualType) {
    ReceiptType type;
    switch (manualType.toLowerCase()) {
      case 'googlepay':
        type = ReceiptType.googlePayDetailed;
        break;
      case 'gpay_clean':
        type = ReceiptType.googlePayClean;
        break;
      default:
        type = ReceiptType.googlePayClean; // Default fallback
    }

    return _amountTemplates.firstWhere(
      (template) => template.type == type,
      orElse: () => _amountTemplates.last, // Default to clean
    );
  }

  /// Get template for detected receipt type (fallback)
  static AmountTemplate getTemplateForType(ReceiptType type) {
    return _amountTemplates.firstWhere(
      (template) => template.type == type,
      orElse: () => _amountTemplates.last, // Default to clean
    );
  }

  /// Apply targeted OCR corrections
  static String applyOCRCorrections(String text) {
    String corrected = text;

    // Fix any rupee symbol misrecognitions
    corrected = corrected.replaceAll(RegExp(r'\bR(\d+)\b'), '₹\$1');
    corrected = corrected.replaceAll(RegExp(r'\bRs(\d+)\b'), '₹\$1');

    // Fix decimal point issues
    corrected = corrected.replaceAll(RegExp(r'₹(\d+)\.(\d+)'), '₹\$1.\$2');
    corrected = corrected.replaceAll(RegExp(r'₹(\d+),(\d+)'), '₹\$1.\$2');

    // Clean up extra spaces
    corrected = corrected.replaceAll(RegExp(r'₹\s+(\d+)'), '₹\$1');

    return corrected;
  }

  /// Extract expense data using template-specific patterns - FOCUSED ON AMOUNT ONLY
  static Map<String, String> extractExpenseDataWithTemplate(String text, AmountTemplate template) {
    Map<String, String> expenseData = {};

    if (kDebugMode) {
      print('Extracting data using template: ${template.name}');
      print('Text to analyze: $text');
    }

    // Try each amount pattern for the specific template
    for (int i = 0; i < template.amountPatterns.length; i++) {
      RegExp pattern = template.amountPatterns[i];
      Match? match = pattern.firstMatch(text);

      if (match != null && match.group(1) != null) {
        String amount = match.group(1)!.replaceAll(',', ''); // Remove commas
        if (kDebugMode) {
          print('Found amount with pattern $i: $amount');
        }

        // Validate amount is reasonable (1-99999)
        double? amountValue = double.tryParse(amount);
        if (amountValue != null && amountValue >= 1 && amountValue <= 99999) {
          expenseData['amount'] = amount;
          if (kDebugMode) {
            print('Valid amount extracted: $amount');
          }
          break;
        }
      }
    }

    // If no amount found with template patterns, try fallback but be more restrictive
    if (expenseData['amount']?.isEmpty ?? true) {
      if (kDebugMode) {
        print('No amount found with template patterns, trying restrictive fallback');
      }

      // More restrictive fallback - only look for very obvious amounts
      List<RegExp> restrictiveFallbackPatterns = [
        RegExp(r'₹(\d{1,4}(?:\.\d{2})?)'),  // Only ₹ with 1-4 digits
        RegExp(r'(?<!\d)(\d{1,4})(?=\s*$)', multiLine: true), // 1-4 digit numbers at end of line only
      ];

      for (RegExp pattern in restrictiveFallbackPatterns) {
        Match? match = pattern.firstMatch(text);
        if (match != null && match.group(1) != null) {
          String amount = match.group(1)!;
          double? amountValue = double.tryParse(amount);

          if (amountValue != null && amountValue >= 1 && amountValue <= 9999) {
            expenseData['amount'] = amount;
            if (kDebugMode) {
              print('Restrictive fallback amount extracted: $amount');
            }
            break;
          }
        }
      }
    }

    // Set simple category
    expenseData['category'] = 'General';
    expenseData['templateUsed'] = template.name;

    return expenseData;
  }
}
