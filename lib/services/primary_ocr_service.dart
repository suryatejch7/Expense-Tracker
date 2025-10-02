import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/transaction_ocr_models.dart' as models;

/// Primary OCR service using Google ML Kit
class PrimaryOcrService {
  static final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extract text from image using Google ML Kit
  static Future<models.OcrResult> extractText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final textBlocks = <models.TextBlock>[];

      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final boundingBox = line.boundingBox;
          textBlocks.add(
            models.TextBlock(
              text: line.text,
              boundingBox: models.BoundingBox(
                x: boundingBox.left.round(),
                y: boundingBox.top.round(),
                width: (boundingBox.right - boundingBox.left).round(),
                height: (boundingBox.bottom - boundingBox.top).round(),
              ),
              confidence: line.confidence ?? 0.0,
              lines: [line.text], // Single line for each TextBlock
              recognizedLanguages: line.recognizedLanguages.map((lang) => lang).toList(),
              cornerPoints: line.cornerPoints.map((point) => models.Point(x: point.x.toDouble(), y: point.y.toDouble())).toList(),
            ),
          );
        }
      }

      return models.OcrResult(
        textBlocks: textBlocks,
        rawText: recognizedText.text,
        processingTime: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Primary OCR failed: $e');
    }
  }

  /// Extract text from multiple region crops
  static Future<Map<String, models.OcrResult>> extractTextFromRegions(
    List<File> regionCrops
  ) async {
    final results = <String, models.OcrResult>{};

    for (int i = 0; i < regionCrops.length; i++) {
      final cropFile = regionCrops[i];
      final regionName = _getRegionNameFromPath(cropFile.path);

      try {
        final result = await extractText(cropFile);
        results[regionName] = result;
      } catch (e) {
        // Log error but continue with other regions
        print('Failed to extract text from region $regionName: $e');
      }
    }

    return results;
  }

  static String _getRegionNameFromPath(String path) {
    final fileName = path.split('/').last;
    if (fileName.contains('amount')) return 'amount';
    if (fileName.contains('payee')) return 'payee';
    if (fileName.contains('date')) return 'date';
    return 'unknown';
  }

  /// Clean up resources
  static void dispose() {
    _textRecognizer.close();
  }
}
