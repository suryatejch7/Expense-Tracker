import '../models/transaction_ocr_models.dart';

/// Service for extracting specific fields from OCR results using app templates
class FieldExtractionService {

  /// Extract transaction fields from OCR results
  static ExtractedTransaction extractFields(
    OcrResult ocrResult,
    PaymentApp app
  ) {
    final template = PaymentAppTemplate.getTemplate(app);

    // Extract individual fields
    final amount = _extractAmount(ocrResult.textBlocks, template);
    final payee = _extractPayee(ocrResult.textBlocks, template);
    final date = _extractDate(ocrResult.textBlocks, template);

    return ExtractedTransaction(
      amount: amount,
      payeeName: payee,
      date: date,
      transactionId: null, // PhonePe transaction ID extraction can be added later
      confidence: _calculateOverallConfidence([amount, payee, date]),
    );
  }

  /// Extract amount using currency patterns and position heuristics
  static String? _extractAmount(List<TextBlock> textBlocks, PaymentAppTemplate template) {
    // For PhonePe, focus specifically on the right 40% area (60%-100% left)
    if (template.app == PaymentApp.phonePe) {
      return _extractPhonePeAmount(textBlocks, template);
    }

    // Sort blocks by confidence and look for currency patterns
    final sortedBlocks = List<TextBlock>.from(textBlocks)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    for (final block in sortedBlocks) {
      final text = block.text.trim();

      // Look for currency symbols and amount patterns
      if (_isAmountText(text)) {
        return _cleanAmountText(text);
      }
    }

    // Fallback: look for amount in specific regions
    return _extractAmountFromRegion(textBlocks, template.fieldRegions['amount']);
  }

  /// Extract amount specifically from PhonePe's optimized crop region
  static String? _extractPhonePeAmount(List<TextBlock> textBlocks, PaymentAppTemplate template) {
    final amountRegion = template.fieldRegions['amount'];
    if (amountRegion == null) return null;

    // Filter text blocks that fall within the amount region (right 40% of cropped area)
    final amountBlocks = textBlocks.where((block) {
      final blockCenterX = (block.boundingBox.x + block.boundingBox.width / 2);
      final blockCenterY = (block.boundingBox.y + block.boundingBox.height / 2);

      // Check if block is in the amount region (60%-100% horizontally)
      return blockCenterX >= (amountRegion.x * 1000) && // Assuming normalized coordinates
             blockCenterX <= ((amountRegion.x + amountRegion.width) * 1000) &&
             blockCenterY >= (amountRegion.y * 1000) &&
             blockCenterY <= ((amountRegion.y + amountRegion.height) * 1000);
    }).toList();

    // Sort by confidence and look for amount patterns
    amountBlocks.sort((a, b) => b.confidence.compareTo(a.confidence));

    for (final block in amountBlocks) {
      final text = block.text.trim();

      // Look for currency symbols and numeric patterns
      if (_isAmountText(text)) {
        final cleanAmount = _cleanAmountText(text);
        if (cleanAmount.isNotEmpty) {
          return cleanAmount;
        }
      }
    }

    // Fallback: look for any numeric value in the amount region
    for (final block in amountBlocks) {
      final text = block.text.trim();
      final numericValue = _extractNumericValue(text);
      if (numericValue != null && numericValue > 0) {
        return '₹$numericValue';
      }
    }

    return null;
  }

  /// Extract numeric value from text
  static double? _extractNumericValue(String text) {
    // Remove all non-numeric characters except decimal point
    final numericText = text.replaceAll(RegExp(r'[^\d.]'), '');
    if (numericText.isEmpty) return null;

    return double.tryParse(numericText);
  }

  /// Extract payee name using position and keyword heuristics
  static String? _extractPayee(List<TextBlock> textBlocks, PaymentAppTemplate template) {
    // Look for text blocks near payee keywords
    final payeeKeywords = template.fieldKeywords['payee'] ?? [];

    for (final keyword in payeeKeywords) {
      for (int i = 0; i < textBlocks.length; i++) {
        final block = textBlocks[i];

        if (block.text.toLowerCase().contains(keyword.toLowerCase())) {
          // Look for payee name in next few blocks
          for (int j = i + 1; j < (i + 3).clamp(0, textBlocks.length); j++) {
            final candidateBlock = textBlocks[j];
            final candidateText = candidateBlock.text.trim();

            if (_isValidPayeeName(candidateText)) {
              return _cleanPayeeName(candidateText);
            }
          }
        }
      }
    }

    // Fallback: extract from payee region
    return _extractPayeeFromRegion(textBlocks, template.fieldRegions['payee']);
  }

  /// Extract date using date patterns and position heuristics
  static String? _extractDate(List<TextBlock> textBlocks, PaymentAppTemplate template) {
    final datePatterns = [
      RegExp(r'\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4}'), // DD/MM/YYYY, DD-MM-YY, etc.
      RegExp(r'\d{1,2}\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{2,4}', caseSensitive: false),
      RegExp(r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2},?\s+\d{2,4}', caseSensitive: false),
      RegExp(r'\d{1,2}\s+(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{2,4}', caseSensitive: false),
    ];

    for (final block in textBlocks) {
      final text = block.text.trim();

      for (final pattern in datePatterns) {
        final match = pattern.firstMatch(text);
        if (match != null) {
          return _cleanDateText(match.group(0)!);
        }
      }
    }

    // Fallback: extract from date region
    return _extractDateFromRegion(textBlocks, template.fieldRegions['date']);
  }

  /// Check if text contains amount information
  static bool _isAmountText(String text) {
    // Check for currency symbols
    if (text.contains('₹') || text.contains('Rs') || text.contains('\$')) {
      return true;
    }

    // Check for amount patterns (numbers with decimals/commas)
    final amountPattern = RegExp(r'\d+[,\.]?\d*');
    final matches = amountPattern.allMatches(text);

    // Must have substantial numeric content
    return matches.isNotEmpty &&
           matches.map((m) => m.group(0)!.length).reduce((a, b) => a + b) > text.length * 0.5;
  }

  /// Check if text is a valid payee name
  static bool _isValidPayeeName(String text) {
    // Filter out common non-name patterns
    if (text.length < 2 || text.length > 50) return false;
    if (RegExp(r'^\d+$').hasMatch(text)) return false; // Pure numbers
    if (RegExp(r'^[^\w\s]+$').hasMatch(text)) return false; // Pure symbols
    if (text.toLowerCase().contains('transaction') ||
        text.toLowerCase().contains('payment') ||
        text.toLowerCase().contains('transfer')) return false;

    return true;
  }

  /// Clean and format amount text
  static String _cleanAmountText(String text) {
    // Remove currency symbols and extra spaces
    String cleaned = text
        .replaceAll('₹', '')
        .replaceAll('Rs', '')
        .replaceAll('\$', '')
        .replaceAll(RegExp(r'[^\d\.,]'), '')
        .trim();

    // Handle comma separators in Indian format
    if (cleaned.contains(',')) {
      cleaned = cleaned.replaceAll(',', '');
    }

    // Ensure proper decimal format
    final parts = cleaned.split('.');
    if (parts.length > 2) {
      cleaned = '${parts[0]}.${parts[1]}'; // Keep only first decimal
    }

    return cleaned;
  }

  /// Clean and format payee name
  static String _cleanPayeeName(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s\-\.]'), '') // Keep only alphanumeric, spaces, hyphens, dots
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim();
  }

  /// Clean and format date text
  static String _cleanDateText(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s\/\-\.]'), '')
        .trim();
  }

  /// Extract amount from specific region
  static String? _extractAmountFromRegion(List<TextBlock> textBlocks, CropRegion? region) {
    if (region == null) return null;

    // This would be implemented with region-specific logic
    // For now, return the first amount-like text found
    for (final block in textBlocks) {
      if (_isAmountText(block.text)) {
        return _cleanAmountText(block.text);
      }
    }

    return null;
  }

  /// Extract payee from specific region
  static String? _extractPayeeFromRegion(List<TextBlock> textBlocks, CropRegion? region) {
    if (region == null) return null;

    // Find the longest valid text block in the region
    String? bestCandidate;
    int maxLength = 0;

    for (final block in textBlocks) {
      final text = block.text.trim();
      if (_isValidPayeeName(text) && text.length > maxLength) {
        bestCandidate = text;
        maxLength = text.length;
      }
    }

    return bestCandidate != null ? _cleanPayeeName(bestCandidate) : null;
  }

  /// Extract date from specific region
  static String? _extractDateFromRegion(List<TextBlock> textBlocks, CropRegion? region) {
    if (region == null) return null;

    final datePatterns = [
      RegExp(r'\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4}'),
      RegExp(r'\d{1,2}\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{2,4}', caseSensitive: false),
    ];

    for (final block in textBlocks) {
      for (final pattern in datePatterns) {
        final match = pattern.firstMatch(block.text);
        if (match != null) {
          return _cleanDateText(match.group(0)!);
        }
      }
    }

    return null;
  }

  /// Calculate overall confidence score
  static double _calculateOverallConfidence(List<String?> fields) {
    final nonNullFields = fields.where((f) => f != null && f.isNotEmpty).length;
    return (nonNullFields / fields.length) * 100;
  }

  /// Fix null comparison warning
  static String? extractAmount(List<TextBlock> textBlocks, PaymentApp app) {
    final template = PaymentAppTemplate.getTemplate(app);
    final amountKeywords = template.fieldKeywords['amount'];

    // Check if keywords exist before using them
    if (amountKeywords != null) {
      // Find amount using keywords
      for (final keyword in amountKeywords) {
        for (int i = 0; i < textBlocks.length; i++) {
          final block = textBlocks[i];
          if (block.text.toLowerCase().contains(keyword.toLowerCase())) {
            // Look for amount in same block or next few blocks
            for (int j = i; j < (i + 3).clamp(0, textBlocks.length); j++) {
              final amountText = textBlocks[j].text;
              final amount = _extractAmountFromText(amountText);
              if (amount.isNotEmpty) {
                return amount;
              }
            }
          }
        }
      }
    }

    // If no keyword-based amount found, search for currency patterns
    for (final block in textBlocks) {
      if (block.text.contains('₹') || block.text.contains('Rs')) {
        final amount = _extractAmountFromText(block.text);
        if (amount.isNotEmpty) {
          return amount;
        }
      }
    }

    return null;
  }

  /// Extract payee name from text blocks
  static String? extractPayee(List<TextBlock> textBlocks, PaymentApp app) {
    final template = PaymentAppTemplate.getTemplate(app);
    final payeeKeywords = template.fieldKeywords['payee'];

    if (payeeKeywords != null) {
      for (final keyword in payeeKeywords) {
        for (int i = 0; i < textBlocks.length; i++) {
          final block = textBlocks[i];
          if (block.text.toLowerCase().contains(keyword.toLowerCase())) {
            // Look for payee in next blocks
            for (int j = i + 1; j < (i + 3).clamp(0, textBlocks.length); j++) {
              final payeeText = textBlocks[j].text.trim();
              if (payeeText.isNotEmpty && _isValidPayeeName(payeeText)) {
                return payeeText;
              }
            }
          }
        }
      }
    }

    return null;
  }

  /// Extract transaction ID using keyword and position heuristics
  static String? extractTransactionId(List<TextBlock> textBlocks, PaymentApp app) {
    final template = PaymentAppTemplate.getTemplate(app);
    final idKeywords = template.fieldKeywords['transactionId'];

    if (idKeywords != null) {
      for (final keyword in idKeywords) {
        for (int i = 0; i < textBlocks.length; i++) {
          final block = textBlocks[i];
          if (block.text.toLowerCase().contains(keyword.toLowerCase())) {
            // Look for transaction ID in same or next block
            for (int j = i; j < (i + 2).clamp(0, textBlocks.length); j++) {
              final idText = textBlocks[j].text.trim();
              if (idText.isNotEmpty && _isValidTransactionId(idText)) {
                return idText;
              }
            }
          }
        }
      }
    }

    return null;
  }

  /// Extract amount from text string
  static String _extractAmountFromText(String text) {
    // Remove currency symbols and clean the text
    final cleanText = text
        .replaceAll('₹', '')
        .replaceAll('Rs', '')
        .replaceAll(RegExp(r'[^\d\.,]'), '')
        .trim();

    if (cleanText.isEmpty) return '';

    // Handle comma separators
    String normalizedText = cleanText;
    if (normalizedText.contains(',')) {
      normalizedText = normalizedText.replaceAll(',', '');
    }

    // Validate numeric format
    final amount = double.tryParse(normalizedText);
    if (amount != null && amount > 0) {
      return amount.toStringAsFixed(2);
    }

    return '';
  }

  /// Validate transaction ID format
  static bool _isValidTransactionId(String text) {
    // Remove whitespace and check length
    final cleanText = text.trim();

    // Transaction ID should be alphanumeric, 6-20 characters
    if (cleanText.length < 6 || cleanText.length > 20) return false;

    // Should contain at least one number
    if (!RegExp(r'\d').hasMatch(cleanText)) return false;

    // Should not be just numbers (that's likely an amount)
    if (RegExp(r'^\d+$').hasMatch(cleanText)) return false;

    // Should contain alphanumeric characters
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(cleanText)) return false;

    return true;
  }

  /// Extract transaction fields using backward compatibility approach
  static ExtractedTransaction extractTransactionFields(
    List<TextBlock> textBlocks,
    PaymentApp app,
  ) {
    // Use the existing extraction methods
    final amount = extractAmount(textBlocks, app);
    final payee = extractPayee(textBlocks, app);
    final transactionId = extractTransactionId(textBlocks, app);

    // Extract date using the existing method
    final template = PaymentAppTemplate.getTemplate(app);
    final date = _extractDate(textBlocks, template);

    return ExtractedTransaction(
      amount: amount,
      payeeName: payee,
      date: date,
      transactionId: transactionId,
      confidence: _calculateOverallConfidence([amount, payee, date, transactionId]),
    );
  }
}
