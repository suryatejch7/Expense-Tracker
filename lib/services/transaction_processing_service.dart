import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/transaction_ocr_models.dart';
import 'image_preprocessing_service.dart';
import 'primary_ocr_service.dart';
import 'field_extraction_service.dart';
import 'text_normalization_service.dart';
import 'tesseract_ocr_service.dart';

/// Main service orchestrating the complete transaction processing pipeline
class TransactionProcessingService {
  
  /// Process transaction screenshot with complete pipeline (PhonePe only)
  static Future<ProcessingResult> processTransactionScreenshot(
    File imageFile,
    {Function(double)? onProgress}
  ) async {
    List<String> processingSteps = [];
    const selectedApp = PaymentApp.phonePe; // Hardcoded since you only use PhonePe

    try {
      onProgress?.call(0.1);
      processingSteps.add('Starting PhonePe transaction processing...');

      // Validate input file
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      final fileSize = await imageFile.length();
      if (fileSize == 0) {
        throw Exception('Image file is empty');
      }

      if (fileSize > 50 * 1024 * 1024) { // 50MB limit
        throw Exception('Image file too large (>50MB)');
      }

      // Step 1: Image Preprocessing - Use dual-crop approach for PhonePe
      onProgress?.call(0.2);
      processingSteps.add('Preprocessing image with PhonePe dual-crop settings...');

      Map<String, File>? dualCrops;
      try {
        // Create separate crops for payee (left 60%) and amount (right 40%)
        dualCrops = await ImagePreprocessingService.preprocessPhonePeDualCrops(
          imageFile
        ).timeout(const Duration(seconds: 30));
      } catch (e) {
        debugPrint('Dual-crop preprocessing failed, using fallback: $e');
        dualCrops = null;
      }

      // Step 2: Dual OCR with Google ML Kit on both crops
      onProgress?.call(0.3);
      processingSteps.add('Extracting text using dual-crop OCR...');

      ExtractedTransaction extractedData;

      if (dualCrops != null) {
        // Process both crops separately for optimal extraction
        final payeeOcr = await PrimaryOcrService.extractText(dualCrops['payee']!)
            .timeout(const Duration(minutes: 1));
        final amountOcr = await PrimaryOcrService.extractText(dualCrops['amount']!)
            .timeout(const Duration(minutes: 1));

        // Extract using the WORKING GitHub logic for payee and CURRENT logic for amount
        final payeeExtracted = FieldExtractionService.extractPayeeFromLeftCrop(payeeOcr.textBlocks);
        final amountExtracted = FieldExtractionService.extractAmountFromRightCrop(amountOcr.textBlocks);

        // Combine results
        extractedData = ExtractedTransaction(
          amount: amountExtracted,
          payeeName: payeeExtracted,
          date: null,
          transactionId: null,
          confidence: _calculateCombinedConfidence([amountExtracted, payeeExtracted]),
        );

        processingSteps.add('Dual-crop extraction completed: ${payeeExtracted != null ? "Payee found" : "Payee not found"}, ${amountExtracted != null ? "Amount found" : "Amount not found"}');
      } else {
        // Fallback to single image processing if dual-crop fails
        final preprocessedImage = await ImagePreprocessingService.preprocessImage(
          imageFile,
          selectedApp
        ).timeout(const Duration(seconds: 30));

        final ocrResult = await PrimaryOcrService.extractText(preprocessedImage)
            .timeout(const Duration(minutes: 2));

        if (ocrResult.textBlocks.isEmpty && ocrResult.rawText.isEmpty) {
          throw Exception('No text found in image. Please ensure the image is clear and contains text.');
        }

        extractedData = FieldExtractionService.extractFields(ocrResult, selectedApp);
        processingSteps.add('Fallback extraction completed');
      }

      // Step 4: Text Normalization (simplified for PhonePe)
      onProgress?.call(0.6);
      processingSteps.add('Processing extracted data...');

      // Skip complex normalization and use extracted data directly
      final normalizedData = extractedData;

      // Step 5: Secondary OCR (DISABLED - Tesseract causing crashes)
      onProgress?.call(0.8);
      processingSteps.add('Finalizing transaction data...');

      // Skip Tesseract OCR entirely to prevent crashes
      // Google ML Kit provides sufficient accuracy for PhonePe transactions
      final enhancedData = normalizedData;

      onProgress?.call(1.0);
      processingSteps.add('PhonePe transaction processing completed successfully!');

      return ProcessingResult(
        success: true,
        extractedTransaction: enhancedData,
        processingSteps: processingSteps,
        confidence: enhancedData.confidence,
      );
      
    } catch (e) {
      debugPrint('Transaction processing error: $e');
      processingSteps.add('Error: ${e.toString()}');

      return ProcessingResult(
        success: false,
        error: e.toString(),
        processingSteps: processingSteps,
        confidence: 0.0,
      );
    } finally {
      // Clean up resources
      try {
        await PrimaryOcrService.dispose();
      } catch (e) {
        debugPrint('Cleanup warning: $e');
      }
    }
  }

  /// Enhance extracted data using existing Tesseract service methods
  static ExtractedTransaction _enhanceWithExistingTesseractService(
    ExtractedTransaction normalizedData,
    Map<String, String> tesseractResults,
  ) {
    try {
      // Use the existing Tesseract service enhancement methods
      final enhancedAmount = TesseractOcrService.enhanceAmountExtraction(
        normalizedData.amount,
        tesseractResults
      );

      final enhancedPayee = TesseractOcrService.enhancePayeeExtraction(
        normalizedData.payeeName,
        tesseractResults
      );

      // Calculate improved confidence based on Tesseract results
      final improvedConfidence = _calculateTesseractEnhancedConfidence(
        enhancedAmount,
        enhancedPayee,
        normalizedData.confidence,
        tesseractResults.isNotEmpty,
      );

      return ExtractedTransaction(
        amount: enhancedAmount,
        payeeName: enhancedPayee,
        date: normalizedData.date,
        transactionId: normalizedData.transactionId,
        confidence: improvedConfidence,
      );
    } catch (e) {
      debugPrint('Enhancement with Tesseract service failed: $e');
      return normalizedData; // Return original if enhancement fails
    }
  }

  /// Calculate enhanced confidence with Tesseract results
  static double _calculateTesseractEnhancedConfidence(
    String? amount,
    String? payee,
    double originalConfidence,
    bool hasTesseractResults,
  ) {
    int successfulFields = 0;
    int totalFields = 2;

    if (amount != null && amount.isNotEmpty) successfulFields++;
    if (payee != null && payee.isNotEmpty) successfulFields++;

    final fieldSuccessRate = (successfulFields / totalFields) * 100;

    // Boost confidence if Tesseract provided additional verification
    if (hasTesseractResults && successfulFields == totalFields) {
      return (originalConfidence * 0.2) + (fieldSuccessRate * 0.8); // Higher weight for Tesseract
    } else if (hasTesseractResults) {
      return (originalConfidence * 0.3) + (fieldSuccessRate * 0.7);
    }

    return (originalConfidence * 0.4) + (fieldSuccessRate * 0.6);
  }

  /// Validate extracted transaction data
  static ValidationResult validateExtractedData(ExtractedTransaction transaction) {
    final issues = <String>[];
    
    if (transaction.amount == null || transaction.amount!.isEmpty) {
      issues.add('Amount not detected');
    } else {
      // Validate amount format
      final amountValue = double.tryParse(transaction.amount!);
      if (amountValue == null || amountValue <= 0) {
        issues.add('Invalid amount format');
      }
    }
    
    if (transaction.payeeName == null || transaction.payeeName!.isEmpty) {
      issues.add('Payee name not detected');
    } else if (transaction.payeeName!.length < 2) {
      issues.add('Payee name too short');
    }
    
    if (transaction.date == null || transaction.date!.isEmpty) {
      issues.add('Date not detected');
    } else {
      // Try to parse the date
      try {
        TextNormalizationService.normalizeDate(transaction.date!);
      } catch (e) {
        issues.add('Invalid date format');
      }
    }
    
    return ValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
      confidence: transaction.confidence,
    );
  }

  /// Clean amount to fix OCR "7" prefix issue
  static String? _cleanAmount(String? amount) {
    if (amount == null || amount.isEmpty) return amount;

    // Remove currency symbol for processing
    String cleaned = amount.replaceAll('₹', '').trim();

    // Fix OCR artifact: if starts with '7' and rest is a valid number, remove the '7'
    if (cleaned.startsWith('7') && cleaned.length > 1) {
      final possibleAmount = cleaned.substring(1);
      final numValue = double.tryParse(possibleAmount);
      // Only remove '7' if the remaining number is plausible (1-99999)
      if (numValue != null && numValue > 0 && numValue < 100000) {
        cleaned = possibleAmount;
      }
    }

    // Return with currency symbol
    return '₹$cleaned';
  }

  /// Calculate combined confidence from multiple fields
  static double _calculateCombinedConfidence(List<String?> fields) {
    final nonNullFields = fields.where((f) => f != null && f.isNotEmpty).length;
    return (nonNullFields / fields.length) * 100;
  }
}

/// Result of the complete processing pipeline
class ProcessingResult {
  final bool success;
  final ExtractedTransaction? extractedTransaction;
  final String? error;
  final List<String> processingSteps;
  final double confidence;

  ProcessingResult({
    required this.success,
    this.extractedTransaction,
    this.error,
    required this.processingSteps,
    this.confidence = 0.0,
  });
}

/// Result of transaction data validation
class ValidationResult {
  final bool isValid;
  final List<String> issues;
  final double confidence;

  ValidationResult({
    required this.isValid,
    required this.issues,
    required this.confidence,
  });
}
