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

      // Step 1: Image Preprocessing (PhonePe optimized crop)
      onProgress?.call(0.2);
      processingSteps.add('Preprocessing image with PhonePe crop settings...');

      File? preprocessedImage;
      try {
        preprocessedImage = await ImagePreprocessingService.preprocessImage(
          imageFile,
          selectedApp
        ).timeout(const Duration(seconds: 30));
      } catch (e) {
        debugPrint('Preprocessing failed, using original image: $e');
        preprocessedImage = imageFile; // Fallback to original
      }

      // Step 2: Primary OCR with Google ML Kit
      onProgress?.call(0.3);
      processingSteps.add('Extracting text using OCR...');

      final ocrResult = await PrimaryOcrService.extractText(preprocessedImage)
          .timeout(const Duration(minutes: 2));

      if (ocrResult.textBlocks.isEmpty && ocrResult.rawText.isEmpty) {
        throw Exception('No text found in image. Please ensure the image is clear and contains text.');
      }

      // Step 3: Field Extraction using PhonePe templates
      onProgress?.call(0.5);
      processingSteps.add('Extracting transaction fields...');

      final extractedData = FieldExtractionService.extractFields(
        ocrResult, 
        selectedApp
      );
      
      // Step 4: Text Normalization (simplified for PhonePe)
      onProgress?.call(0.6);
      processingSteps.add('Processing extracted data...');

      // Skip complex normalization and use extracted data directly
      final normalizedData = extractedData;

      // Step 5: Secondary OCR (optional, skip if failing)
      onProgress?.call(0.8);
      processingSteps.add('Enhancing field accuracy...');

      try {
        final tesseractResults = await TesseractOcrService.performSecondaryOcr(
          imageFile,
          ocrResult.textBlocks,
          selectedApp,
        ).timeout(const Duration(seconds: 45));

        // Step 6: Enhance fields with Tesseract results
        final enhancedData = _enhanceWithExistingTesseractService(normalizedData, tesseractResults);

        onProgress?.call(1.0);
        processingSteps.add('PhonePe transaction processing completed successfully!');

        return ProcessingResult(
          success: true,
          extractedTransaction: enhancedData,
          processingSteps: processingSteps,
          confidence: enhancedData.confidence,
        );

      } catch (secondaryOcrError) {
        debugPrint('Secondary OCR failed, continuing with primary results: $secondaryOcrError');
        processingSteps.add('Using primary OCR results (secondary enhancement skipped)');
      }

      onProgress?.call(1.0);
      processingSteps.add('PhonePe transaction processing completed!');

      return ProcessingResult(
        success: true,
        extractedTransaction: normalizedData,
        processingSteps: processingSteps,
        confidence: normalizedData.confidence,
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
