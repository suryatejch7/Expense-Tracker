import 'dart:io';
import '../models/transaction_ocr_models.dart';
import 'image_preprocessing_service.dart';
import 'primary_ocr_service.dart';
import 'field_extraction_service.dart';
import 'text_normalization_service.dart';
import 'tesseract_ocr_service.dart';

/// Main service orchestrating the complete transaction processing pipeline
class TransactionProcessingService {
  
  /// Process transaction screenshot with complete pipeline
  static Future<ProcessingResult> processTransactionScreenshot(
    File imageFile, 
    PaymentApp selectedApp,
    {Function(double)? onProgress}
  ) async {
    try {
      onProgress?.call(0.1);
      
      // Step 1: Image Preprocessing
      onProgress?.call(0.2);
      final preprocessedImage = await ImagePreprocessingService.preprocessImage(
        imageFile, 
        selectedApp
      );
      
      // Step 2: Primary OCR with Google ML Kit
      onProgress?.call(0.3);
      final ocrResult = await PrimaryOcrService.extractText(preprocessedImage);
      
      // Step 3: Field Extraction using templates
      onProgress?.call(0.5);
      final extractedData = FieldExtractionService.extractFields(
        ocrResult, 
        selectedApp
      );
      
      // Step 4: Text Normalization
      onProgress?.call(0.6);
      final normalizedData = await _normalizeExtractedData(extractedData);
      
      // Step 5: Secondary OCR with Tesseract/EasyOCR for critical fields
      onProgress?.call(0.8);
      final tesseractResults = await TesseractOcrService.performSecondaryOcr(
        imageFile,
        ocrResult.textBlocks,
        selectedApp,
      );

      // Step 6: Enhance fields with Tesseract results
      final enhancedData = _enhanceWithTesseractResults(normalizedData, tesseractResults);

      onProgress?.call(1.0);
      
      // Clean up temporary files
      await _cleanupTempFiles([preprocessedImage]);
      
      return ProcessingResult(
        success: true,
        extractedTransaction: enhancedData,
        processingSteps: [
          'Image preprocessing completed',
          'Primary OCR extraction with Google ML Kit',
          'Template-based field extraction for ${selectedApp.displayName}',
          'Text normalization and symbol correction',
          'Secondary OCR with Tesseract/EasyOCR for critical fields',
          'Field enhancement and validation completed',
        ],
      );
      
    } catch (e) {
      return ProcessingResult(
        success: false,
        error: 'Transaction processing failed: $e',
        processingSteps: ['Processing failed at pipeline stage'],
      );
    }
  }

  /// Enhance extracted data with Tesseract OCR results
  static ExtractedTransaction _enhanceWithTesseractResults(
    ExtractedTransaction normalizedData,
    Map<String, String> tesseractResults,
  ) {
    // Use Tesseract results to enhance or replace primary extractions
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
      date: normalizedData.date, // Use original date from primary extraction
      transactionId: normalizedData.transactionId,
      sourceApp: normalizedData.sourceApp,
      confidence: improvedConfidence,
      extractionTime: DateTime.now(),
    );
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

  /// Normalize extracted data using text normalization service
  static Future<ExtractedTransaction> _normalizeExtractedData(
    ExtractedTransaction extracted
  ) async {
    try {
      final normalizedAmount = extracted.amount != null 
        ? TextNormalizationService.normalizeAmount(extracted.amount!)
        : null;
        
      final normalizedPayee = extracted.payeeName != null
        ? TextNormalizationService.normalizePayeeName(extracted.payeeName!)
        : null;
        
      final normalizedDate = extracted.date != null
        ? TextNormalizationService.normalizeDate(extracted.date!)
        : null;

      return ExtractedTransaction(
        amount: normalizedAmount,
        payeeName: normalizedPayee,
        date: normalizedDate,
        sourceApp: extracted.sourceApp,
        confidence: _calculateImprovedConfidence(
          normalizedAmount, 
          normalizedPayee, 
          normalizedDate,
          extracted.confidence
        ),
        extractionTime: extracted.extractionTime,
      );
    } catch (e) {
      // Return original data if normalization fails
      return extracted;
    }
  }

  /// Calculate improved confidence based on normalization success
  static double _calculateImprovedConfidence(
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
    
    // Combine with original confidence
    return (originalConfidence * 0.4) + (fieldSuccessRate * 0.6);
  }

  /// Clean up temporary files
  static Future<void> _cleanupTempFiles(List<File> tempFiles) async {
    for (final file in tempFiles) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Failed to cleanup temp file ${file.path}: $e');
      }
    }
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

  ProcessingResult({
    required this.success,
    this.extractedTransaction,
    this.error,
    required this.processingSteps,
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
