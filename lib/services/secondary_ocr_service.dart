import 'dart:io';
import '../models/transaction_ocr_models.dart';
import 'text_normalization_service.dart';

/// Secondary OCR service for enhanced accuracy on critical fields
class SecondaryOcrService {

  /// Perform enhanced OCR on specific field regions for better accuracy
  static Future<ExtractedTransaction> enhanceFieldExtraction(
    File originalImage,
    PaymentApp app,
    ExtractedTransaction primaryResult,
    List<TextBlock> textBlocks,
  ) async {
    try {
      // Create enhanced field extractions
      String? enhancedAmount = primaryResult.amount;
      String? enhancedPayee = primaryResult.payeeName;
      String? enhancedDate = primaryResult.date;

      // If primary extraction failed or has low confidence, try enhanced methods
      if (enhancedAmount == null || enhancedAmount.isEmpty) {
        enhancedAmount = await _extractAmountWithFallback(textBlocks, app);
      }

      if (enhancedPayee == null || enhancedPayee.isEmpty) {
        enhancedPayee = await _extractPayeeWithFallback(textBlocks, app);
      }

      if (enhancedDate == null || enhancedDate.isEmpty) {
        enhancedDate = await _extractDateWithFallback(textBlocks, app);
      }

      // Calculate improved confidence
      final confidence = _calculateEnhancedConfidence(
        enhancedAmount,
        enhancedPayee,
        enhancedDate,
        primaryResult.confidence
      );

      return ExtractedTransaction(
        amount: enhancedAmount,
        payeeName: enhancedPayee,
        date: enhancedDate,
        transactionId: primaryResult.transactionId,
        sourceApp: primaryResult.sourceApp,
        confidence: confidence,
        extractionTime: DateTime.now(),
      );

    } catch (e) {
      // Return original result if enhancement fails
      return primaryResult;
    }
  }

  /// Enhanced amount extraction with multiple fallback strategies
  static Future<String?> _extractAmountWithFallback(
    List<TextBlock> textBlocks,
    PaymentApp app
  ) async {
    // Strategy 1: Look for currency symbols with high confidence
    for (final block in textBlocks) {
      if (block.confidence > 0.8 && _containsCurrencySymbol(block.text)) {
        final normalized = TextNormalizationService.normalizeAmount(block.text);
        if (normalized != null) return normalized;
      }
    }

    // Strategy 2: Look for large numbers that could be amounts
    final numericBlocks = textBlocks.where((block) =>
      RegExp(r'\d+[,\.]?\d*').hasMatch(block.text) &&
      block.text.replaceAll(RegExp(r'[^\d]'), '').length >= 2
    ).toList();

    for (final block in numericBlocks) {
      final normalized = TextNormalizationService.normalizeAmount(block.text);
      if (normalized != null) {
        final amount = double.tryParse(normalized);
        if (amount != null && amount > 1 && amount < 1000000) { // Reasonable amount range
          return normalized;
        }
      }
    }

    // Strategy 3: Use template-based positioning
    final template = PaymentAppTemplate.getTemplate(app);
    final amountKeywords = template.fieldKeywords['amount'] ?? [];

    for (final keyword in amountKeywords) {
      for (int i = 0; i < textBlocks.length; i++) {
        if (textBlocks[i].text.toLowerCase().contains(keyword.toLowerCase())) {
          // Look in next few blocks for amount
          for (int j = i + 1; j < (i + 3).clamp(0, textBlocks.length); j++) {
            final normalized = TextNormalizationService.normalizeAmount(textBlocks[j].text);
            if (normalized != null) return normalized;
          }
        }
      }
    }

    return null;
  }

  /// Enhanced payee extraction with context awareness
  static Future<String?> _extractPayeeWithFallback(
    List<TextBlock> textBlocks,
    PaymentApp app
  ) async {
    final template = PaymentAppTemplate.getTemplate(app);
    final payeeKeywords = template.fieldKeywords['payee'] ?? [];

    // Strategy 1: Look after payee keywords
    for (final keyword in payeeKeywords) {
      for (int i = 0; i < textBlocks.length; i++) {
        if (textBlocks[i].text.toLowerCase().contains(keyword.toLowerCase())) {
          // Look in next few blocks for payee name
          for (int j = i + 1; j < (i + 3).clamp(0, textBlocks.length); j++) {
            final candidateText = textBlocks[j].text.trim();
            if (_isValidPayeeName(candidateText)) {
              final normalized = TextNormalizationService.normalizePayeeName(candidateText);
              if (normalized != null && normalized.isNotEmpty) return normalized;
            }
          }
        }
      }
    }

    // Strategy 2: Look for person/business name patterns
    for (final block in textBlocks) {
      final text = block.text.trim();
      if (_looksLikePersonName(text)) {
        final normalized = TextNormalizationService.normalizePayeeName(text);
        if (normalized != null && normalized.isNotEmpty) return normalized;
      }
    }

    return null;
  }

  /// Enhanced date extraction with multiple format support
  static Future<String?> _extractDateWithFallback(
    List<TextBlock> textBlocks,
    PaymentApp app
  ) async {
    // Strategy 1: Look for standard date patterns
    final datePatterns = [
      RegExp(r'\b(\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4})\b'),
      RegExp(r'\b(\d{1,2}\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{2,4})\b', caseSensitive: false),
      RegExp(r'\b(Today|Yesterday)\b', caseSensitive: false),
      RegExp(r'\b(\d{1,2}:\d{2}\s*(AM|PM)?)\b', caseSensitive: false),
    ];

    for (final block in textBlocks) {
      for (final pattern in datePatterns) {
        final match = pattern.firstMatch(block.text);
        if (match != null) {
          String dateStr = match.group(0)!;

          // Handle relative dates
          if (dateStr.toLowerCase() == 'today') {
            return DateTime.now().toIso8601String().split('T')[0];
          } else if (dateStr.toLowerCase() == 'yesterday') {
            return DateTime.now().subtract(Duration(days: 1)).toIso8601String().split('T')[0];
          }

          final normalized = TextNormalizationService.normalizeDate(dateStr);
          if (normalized != null) return normalized;
        }
      }
    }

    // Strategy 2: Look for date context keywords
    final template = PaymentAppTemplate.getTemplate(app);
    final dateKeywords = template.fieldKeywords['date'] ?? [];

    for (final keyword in dateKeywords) {
      for (int i = 0; i < textBlocks.length; i++) {
        if (textBlocks[i].text.toLowerCase().contains(keyword.toLowerCase())) {
          // Look in nearby blocks for date
          for (int j = (i - 1).clamp(0, textBlocks.length); j < (i + 2).clamp(0, textBlocks.length); j++) {
            if (j != i) {
              final normalized = TextNormalizationService.normalizeDate(textBlocks[j].text);
              if (normalized != null) return normalized;
            }
          }
        }
      }
    }

    return null;
  }

  /// Check if text contains currency symbols
  static bool _containsCurrencySymbol(String text) {
    return text.contains('₹') || text.contains('Rs') || text.contains('\$') ||
           text.contains('INR') || text.contains('rupee');
  }

  /// Check if text is a valid payee name
  static bool _isValidPayeeName(String text) {
    if (text.length < 2 || text.length > 50) return false;
    if (RegExp(r'^\d+$').hasMatch(text)) return false; // Pure numbers
    if (RegExp(r'^[^\w\s]+$').hasMatch(text)) return false; // Pure symbols
    if (text.toLowerCase().contains('transaction') ||
        text.toLowerCase().contains('payment') ||
        text.toLowerCase().contains('transfer') ||
        text.toLowerCase().contains('upi') ||
        text.toLowerCase().contains('imps')) return false;

    return true;
  }

  /// Check if text looks like a person or business name
  static bool _looksLikePersonName(String text) {
    // Check for proper case patterns
    if (RegExp(r'^[A-Z][a-z]+(\s+[A-Z][a-z]+)*$').hasMatch(text)) return true;

    // Check for business patterns
    if (text.contains(' Store') || text.contains(' Shop') ||
        text.contains(' Mart') || text.contains(' Ltd') ||
        text.contains(' Pvt') || text.contains(' Co')) return true;

    // Check for common name patterns
    if (text.split(' ').length >= 2 && text.split(' ').length <= 4) {
      return !RegExp(r'\d').hasMatch(text); // No digits in names
    }

    return false;
  }

  /// Calculate enhanced confidence score
  static double _calculateEnhancedConfidence(
    String? amount,
    String? payee,
    String? date,
    double originalConfidence,
  ) {
    int successfulFields = 0;
    int totalFields = 3;

    if (amount != null && amount.isNotEmpty) successfulFields++;
    if (payee != null && payee.isNotEmpty) successfulFields++;
    if (date != null && date.isNotEmpty) successfulFields++;

    final fieldSuccessRate = (successfulFields / totalFields) * 100;

    // Boost confidence if all fields are found
    if (successfulFields == totalFields) {
      return (originalConfidence * 0.3) + (fieldSuccessRate * 0.7);
    }

    return (originalConfidence * 0.5) + (fieldSuccessRate * 0.5);
  }
}
