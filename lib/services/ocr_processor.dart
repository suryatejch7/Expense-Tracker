import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/foundation.dart';
import '../models/receipt_types.dart';
import '../services/ocr_service.dart';
import '../services/image_cropping_service.dart';

class OCRProcessor {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Main OCR processing method with manual receipt type selection
  Future<Map<String, dynamic>> processImageWithManualType(File imageFile, String manualReceiptType) async {
    try {
      if (kDebugMode) {
        print('Processing image with manual type: $manualReceiptType');
      }

      // Get template based on manual selection
      AmountTemplate template = OCRService.getTemplateForManualType(manualReceiptType);

      if (kDebugMode) {
        print('Using template: ${template.name}');
        print('Crop bounds: ${template.cropBounds}');
      }

      // Perform template-specific cropping
      File? croppedImage = await ImageCroppingService.smartCropUsingTemplate(imageFile, template);
      File imageToProcess = croppedImage ?? imageFile;

      // OCR on cropped image
      final InputImage croppedInputImage = InputImage.fromFile(imageToProcess);
      final RecognizedText finalRecognizedText = await _textRecognizer.processImage(croppedInputImage);

      String extractedText = finalRecognizedText.text.isEmpty
          ? 'No text found in cropped image'
          : finalRecognizedText.text;

      if (kDebugMode) {
        print('OCR text from cropped area: $extractedText');
      }

      // Apply corrections and extract data using template
      String correctedText = OCRService.applyOCRCorrections(extractedText);
      Map<String, String> expenseData = OCRService.extractExpenseDataWithTemplate(correctedText, template);

      // Clean up temporary cropped file
      if (croppedImage != null && await croppedImage.exists()) {
        await croppedImage.delete();
      }

      return {
        'extractedText': correctedText,
        'expenseData': expenseData,
        'receiptType': template.type,
        'manualType': manualReceiptType,
        'success': true,
      };

    } catch (e) {
      if (kDebugMode) {
        print('OCR processing error: $e');
      }
      return {
        'extractedText': 'Error processing image: $e',
        'expenseData': <String, String>{},
        'receiptType': ReceiptType.unknown,
        'manualType': manualReceiptType,
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Legacy method for automatic detection (fallback)
  Future<Map<String, dynamic>> processImage(File imageFile) async {
    // Default to clean type for backward compatibility
    return await processImageWithManualType(imageFile, 'gpay_clean');
  }

  /// Dispose method to clean up resources
  void dispose() {
    _textRecognizer.close();
  }
}
