import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../models/transaction_ocr_models.dart';
import 'image_preprocessing_service.dart';

/// Secondary OCR service using Tesseract/EasyOCR for enhanced accuracy on critical fields
class TesseractOcrService {
  static const MethodChannel _channel = MethodChannel('tesseract_ocr');

  /// Perform secondary OCR on specific field regions using Tesseract
  static Future<Map<String, String>> performSecondaryOcr(
    File originalImage,
    List<TextBlock> primaryTextBlocks,
    PaymentApp app,
  ) async {
    final results = <String, String>{};

    try {
      // Create narrow crops around detected text blocks for critical fields
      final criticalFields = await _createCriticalFieldCrops(
        originalImage,
        primaryTextBlocks,
        app
      );

      // Process each critical field with Tesseract
      for (final entry in criticalFields.entries) {
        final fieldName = entry.key;
        final cropFile = entry.value;

        try {
          final tesseractResult = await _runTesseractOcr(cropFile, fieldName);
          if (tesseractResult.isNotEmpty) {
            results[fieldName] = tesseractResult;
          }
        } catch (e) {
          print('Tesseract OCR failed for $fieldName: $e');
          // Fallback to EasyOCR if Tesseract fails
          try {
            final easyOcrResult = await _runEasyOcr(cropFile, fieldName);
            if (easyOcrResult.isNotEmpty) {
              results[fieldName] = easyOcrResult;
            }
          } catch (e2) {
            print('EasyOCR also failed for $fieldName: $e2');
          }
        }

        // Clean up temporary crop file
        if (await cropFile.exists()) {
          await cropFile.delete();
        }
      }

    } catch (e) {
      print('Secondary OCR pipeline failed: $e');
    }

    return results;
  }

  /// Create narrow crops around detected amount text blocks
  static Future<Map<String, File>> _createCriticalFieldCrops(
    File originalImage,
    List<TextBlock> textBlocks,
    PaymentApp app,
  ) async {
    final crops = <String, File>{};

    // Find amount text blocks (containing currency symbols)
    final amountBlocks = textBlocks.where((block) =>
      block.text.contains('₹') ||
      block.text.contains('Rs') ||
      RegExp(r'\d+[,\.]?\d*').hasMatch(block.text)
    ).toList();

    // Find payee text blocks (after keywords)
    final template = PaymentAppTemplate.getTemplate(app);
    final payeeKeywords = template.fieldKeywords['payee'] ?? [];
    final payeeBlocks = <TextBlock>[];

    for (final keyword in payeeKeywords) {
      for (int i = 0; i < textBlocks.length; i++) {
        if (textBlocks[i].text.toLowerCase().contains(keyword.toLowerCase())) {
          // Look for payee in next few blocks
          for (int j = i + 1; j < (i + 3).clamp(0, textBlocks.length); j++) {
            payeeBlocks.add(textBlocks[j]);
          }
        }
      }
    }

    // Create crops for each field type
    if (amountBlocks.isNotEmpty) {
      final amountCrop = await _createExpandedCrop(
        originalImage,
        amountBlocks.first.boundingBox,
        'amount'
      );
      if (amountCrop != null) crops['amount'] = amountCrop;
    }

    if (payeeBlocks.isNotEmpty) {
      final payeeCrop = await _createExpandedCrop(
        originalImage,
        payeeBlocks.first.boundingBox,
        'payee'
      );
      if (payeeCrop != null) crops['payee'] = payeeCrop;
    }

    return crops;
  }

  /// Create expanded crop around text bounding box
  static Future<File?> _createExpandedCrop(
    File originalImage,
    BoundingBox boundingBox,
    String fieldName,
  ) async {
    try {
      final bytes = await originalImage.readAsBytes();

      // Use platform channel to create precise crop
      final cropBytes = await _channel.invokeMethod('createCrop', {
        'imageBytes': bytes,
        'x': boundingBox.x - 10, // Add padding
        'y': boundingBox.y - 10,
        'width': boundingBox.width + 20,
        'height': boundingBox.height + 20,
      });

      if (cropBytes != null) {
        final cropPath = '${originalImage.parent.path}/tesseract_crop_${fieldName}_${DateTime.now().millisecondsSinceEpoch}.png';
        final cropFile = File(cropPath);
        await cropFile.writeAsBytes(cropBytes);
        return cropFile;
      }
    } catch (e) {
      print('Failed to create crop for $fieldName: $e');
    }

    return null;
  }

  /// Run Tesseract OCR on crop with field-specific configuration
  static Future<String> _runTesseractOcr(File cropFile, String fieldName) async {
    final bytes = await cropFile.readAsBytes();

    // Configure Tesseract based on field type
    String config = '';
    switch (fieldName) {
      case 'amount':
        config = '-c tessedit_char_whitelist=0123456789.,₹Rs --psm 8'; // Numbers and currency
        break;
      case 'payee':
        config = '--psm 7'; // Single text line
        break;
    }

    try {
      final result = await _channel.invokeMethod('runTesseract', {
        'imageBytes': bytes,
        'config': config,
        'fieldType': fieldName,
      });

      return result?.toString().trim() ?? '';
    } catch (e) {
      throw Exception('Tesseract OCR failed: $e');
    }
  }

  /// Run EasyOCR as fallback
  static Future<String> _runEasyOcr(File cropFile, String fieldName) async {
    final bytes = await cropFile.readAsBytes();

    try {
      final result = await _channel.invokeMethod('runEasyOCR', {
        'imageBytes': bytes,
        'fieldType': fieldName,
        'languages': ['en'], // English only for better performance
      });

      return result?.toString().trim() ?? '';
    } catch (e) {
      throw Exception('EasyOCR failed: $e');
    }
  }

  /// Enhanced amount extraction with Tesseract results
  static String? enhanceAmountExtraction(
    String? primaryAmount,
    Map<String, String> tesseractResults,
  ) {
    if (tesseractResults.containsKey('amount')) {
      final tesseractAmount = tesseractResults['amount']!;

      // Apply symbol corrections for common misreads
      String corrected = tesseractAmount
          .replaceAll('7', '₹') // Common misread
          .replaceAll('F', '₹')
          .replaceAll('Z', '7')
          .replaceAll('S', '5')
          .replaceAll('O', '0')
          .replaceAll('I', '1');

      // Extract numeric value
      final cleanAmount = corrected
          .replaceAll('₹', '')
          .replaceAll('Rs', '')
          .replaceAll(RegExp(r'[^\d\.,]'), '')
          .trim();

      if (cleanAmount.isNotEmpty) {
        final amount = double.tryParse(cleanAmount.replaceAll(',', ''));
        if (amount != null && amount > 0) {
          return amount.toStringAsFixed(2);
        }
      }
    }

    return primaryAmount; // Fallback to primary result
  }

  /// Enhanced payee extraction with Tesseract results
  static String? enhancePayeeExtraction(
    String? primaryPayee,
    Map<String, String> tesseractResults,
  ) {
    if (tesseractResults.containsKey('payee')) {
      final tesseractPayee = tesseractResults['payee']!;

      // Clean and validate
      final cleaned = tesseractPayee
          .replaceAll(RegExp(r'[^\w\s\-\.]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (cleaned.length >= 2 && cleaned.length <= 50) {
        // Check if it looks like a valid name
        if (!RegExp(r'^\d+$').hasMatch(cleaned) &&
            !cleaned.toLowerCase().contains('transaction')) {
          return cleaned;
        }
      }
    }

    return primaryPayee; // Fallback to primary result
  }
}
