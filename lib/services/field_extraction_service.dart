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

    return ExtractedTransaction(
      amount: amount,
      payeeName: payee,
      date: null, // Date extraction completely removed
      transactionId: null,
      confidence: _calculateOverallConfidence([amount, payee]),
    );
  }

  /// Extract amount using currency patterns and position heuristics
  static String? _extractAmount(List<TextBlock> textBlocks, PaymentAppTemplate template) {
    // For PhonePe, use region-based extraction with your specified coordinates
    if (template.app == PaymentApp.phonePe) {
      return _extractPhonePeAmount(textBlocks, template);
    }

    // Simple approach for other apps: look for currency patterns in all text blocks
    for (final block in textBlocks) {
      final text = block.text.trim();

      // Look for ₹ symbol followed by numbers
      final rupeePattern = RegExp(r'₹\s*(\d+(?:[,\.]\d+)*)');
      final rupeeMatch = rupeePattern.firstMatch(text);
      if (rupeeMatch != null) {
        final amount = rupeeMatch.group(1)!.replaceAll(',', '');
        final numValue = double.tryParse(amount);
        if (numValue != null && numValue > 0 && numValue < 100000) {
          return '₹$amount';
        }
      }

      // Look for Rs followed by numbers
      final rsPattern = RegExp(r'Rs\.?\s*(\d+(?:[,\.]\d+)*)');
      final rsMatch = rsPattern.firstMatch(text);
      if (rsMatch != null) {
        final amount = rsMatch.group(1)!.replaceAll(',', '');
        final numValue = double.tryParse(amount);
        if (numValue != null && numValue > 0 && numValue < 100000) {
          return '₹$amount';
        }
      }

      // Look for standalone numbers that could be amounts
      final numberPattern = RegExp(r'\b(\d{1,5}(?:\.\d{1,2})?)\b');
      final numberMatch = numberPattern.firstMatch(text);
      if (numberMatch != null) {
        final amount = numberMatch.group(1)!;
        final numValue = double.tryParse(amount);
        if (numValue != null && numValue > 10 && numValue < 50000) {
          return '₹$amount';
        }
      }
    }

    return null;
  }

  /// Extract amount specifically from PhonePe's optimized crop region
  static String? _extractPhonePeAmount(List<TextBlock> textBlocks, PaymentAppTemplate template) {
    final amountRegion = template.fieldRegions['amount'];
    if (amountRegion == null) return null;

    // Get image dimensions from text blocks (approximate)
    double maxX = 0, maxY = 0;
    for (final block in textBlocks) {
      final rightX = (block.boundingBox.x + block.boundingBox.width).toDouble();
      final bottomY = (block.boundingBox.y + block.boundingBox.height).toDouble();
      if (rightX > maxX) maxX = rightX;
      if (bottomY > maxY) maxY = bottomY;
    }

    // If we can't determine image dimensions, fall back to simple extraction
    if (maxX == 0 || maxY == 0) {
      return _extractAmountSimple(textBlocks);
    }

    // Filter text blocks that fall within the amount region
    // Top 17%, Bottom 21% (so 4% height strip), Right 40% (60%-100% from left)
    final amountBlocks = textBlocks.where((block) {
      final blockCenterX = block.boundingBox.x + (block.boundingBox.width / 2);
      final blockCenterY = block.boundingBox.y + (block.boundingBox.height / 2);

      // Convert region coordinates to pixel coordinates
      final regionLeft = 0.6 * maxX;   // 60% from left (right 40% for amount)
      final regionRight = 1.0 * maxX;  // 100% from left
      final regionTop = 0.17 * maxY;   // 17% from top
      final regionBottom = 0.21 * maxY; // 21% from top (4% height strip)

      // Check if block center is in the amount region
      return blockCenterX >= regionLeft &&
             blockCenterX <= regionRight &&
             blockCenterY >= regionTop &&
             blockCenterY <= regionBottom;
    }).toList();

    // Sort by confidence and look for amount patterns
    amountBlocks.sort((a, b) => b.confidence.compareTo(a.confidence));

    // First pass: look for currency symbols
    for (final block in amountBlocks) {
      final text = block.text.trim();

      // Look for ₹ symbol followed by numbers
      final rupeePattern = RegExp(r'₹\s*(\d+(?:[,\.]\d+)*)');
      final rupeeMatch = rupeePattern.firstMatch(text);
      if (rupeeMatch != null) {
        final amount = rupeeMatch.group(1)!.replaceAll(',', '');
        final numValue = double.tryParse(amount);
        if (numValue != null && numValue > 0 && numValue < 100000) {
          return '₹$amount';
        }
      }

      // Look for Rs followed by numbers
      final rsPattern = RegExp(r'Rs\.?\s*(\d+(?:[,\.]\d+)*)');
      final rsMatch = rsPattern.firstMatch(text);
      if (rsMatch != null) {
        final amount = rsMatch.group(1)!.replaceAll(',', '');
        final numValue = double.tryParse(amount);
        if (numValue != null && numValue > 0 && numValue < 100000) {
          return '₹$amount';
        }
      }
    }

    // Second pass: look for standalone numbers in the region
    for (final block in amountBlocks) {
      final text = block.text.trim();
      final numericValue = _extractNumericValue(text);
      if (numericValue != null && numericValue > 10 && numericValue < 50000) {
        return '₹${numericValue.toStringAsFixed(numericValue == numericValue.roundToDouble() ? 0 : 2)}';
      }
    }

    // Fallback: use simple extraction if region-based fails
    return _extractAmountSimple(textBlocks);
  }

  /// Simple amount extraction as fallback
  static String? _extractAmountSimple(List<TextBlock> textBlocks) {
    for (final block in textBlocks) {
      final text = block.text.trim();

      // Look for ₹ symbol followed by numbers
      final rupeePattern = RegExp(r'₹\s*(\d+(?:[,\.]\d+)*)');
      final rupeeMatch = rupeePattern.firstMatch(text);
      if (rupeeMatch != null) {
        final amount = rupeeMatch.group(1)!.replaceAll(',', '');
        final numValue = double.tryParse(amount);
        if (numValue != null && numValue > 0 && numValue < 100000) {
          return '₹$amount';
        }
      }

      // Look for Rs followed by numbers
      final rsPattern = RegExp(r'Rs\.?\s*(\d+(?:[,\.]\d+)*)');
      final rsMatch = rsPattern.firstMatch(text);
      if (rsMatch != null) {
        final amount = rsMatch.group(1)!.replaceAll(',', '');
        final numValue = double.tryParse(amount);
        if (numValue != null && numValue > 0 && numValue < 100000) {
          return '₹$amount';
        }
      }

      // Look for standalone numbers
      final numberPattern = RegExp(r'\b(\d{1,5}(?:\.\d{1,2})?)\b');
      final numberMatch = numberPattern.firstMatch(text);
      if (numberMatch != null) {
        final amount = numberMatch.group(1)!;
        final numValue = double.tryParse(amount);
        if (numValue != null && numValue > 10 && numValue < 50000) {
          return '₹$amount';
        }
      }
    }
    return null;
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

    return ExtractedTransaction(
      amount: amount,
      payeeName: payee,
      date: null, // Date extraction completely removed
      transactionId: transactionId,
      confidence: _calculateOverallConfidence([amount, payee, transactionId]),
    );
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
    // For PhonePe, use region-based extraction in the left 60% of the optimized strip
    if (template.app == PaymentApp.phonePe) {
      return _extractPhonePePayee(textBlocks, template);
    }

    // Look for text blocks near payee keywords for other apps
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

  /// Extract payee specifically from PhonePe's optimized crop region (left 60%)
  static String? _extractPhonePePayee(List<TextBlock> textBlocks, PaymentAppTemplate template) {
    // Get image dimensions from text blocks (approximate)
    double maxX = 0, maxY = 0;
    for (final block in textBlocks) {
      final rightX = (block.boundingBox.x + block.boundingBox.width).toDouble();
      final bottomY = (block.boundingBox.y + block.boundingBox.height).toDouble();
      if (rightX > maxX) maxX = rightX;
      if (bottomY > maxY) maxY = bottomY;
    }

    // If we can't determine image dimensions, fall back to keyword search
    if (maxX == 0 || maxY == 0) {
      return _extractPayeeWithKeywords(textBlocks, template);
    }

    // Filter text blocks that fall within the payee region
    // Top 17%, Bottom 21% (so 4% height strip), Left 60% (0%-60% from left)
    final payeeBlocks = textBlocks.where((block) {
      final blockCenterX = block.boundingBox.x + (block.boundingBox.width / 2);
      final blockCenterY = block.boundingBox.y + (block.boundingBox.height / 2);

      // Convert region coordinates to pixel coordinates
      final regionLeft = 0.0 * maxX;   // 0% from left
      final regionRight = 0.6 * maxX;  // 60% from left (left 60% for payee)
      final regionTop = 0.17 * maxY;   // 17% from top
      final regionBottom = 0.21 * maxY; // 21% from top (4% height strip)

      // Check if block center is in the payee region
      return blockCenterX >= regionLeft &&
             blockCenterX <= regionRight &&
             blockCenterY >= regionTop &&
             blockCenterY <= regionBottom;
    }).toList();

    // Sort by confidence and look for valid payee names
    payeeBlocks.sort((a, b) => b.confidence.compareTo(a.confidence));

    // Find the best payee candidate in the region
    for (final block in payeeBlocks) {
      final text = block.text.trim();

      if (_isValidPayeeName(text)) {
        return _cleanPayeeName(text);
      }
    }

    // Fallback: use keyword-based extraction
    return _extractPayeeWithKeywords(textBlocks, template);
  }

  /// Extract payee using keyword-based approach as fallback
  static String? _extractPayeeWithKeywords(List<TextBlock> textBlocks, PaymentAppTemplate template) {
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

    return null;
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
        text.toLowerCase().contains('transfer') ||
        text.toLowerCase().contains('upi') ||
        text.toLowerCase().contains('phonepe')) {
      return false;
    }

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
}
