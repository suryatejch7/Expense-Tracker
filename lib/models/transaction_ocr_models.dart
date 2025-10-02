import 'package:flutter/material.dart';

/// Enum for supported payment apps
enum PaymentApp {
  phonePe,
  googlePay,
  paytm,
  unknown;

  String get displayName {
    switch (this) {
      case PaymentApp.phonePe:
        return 'PhonePe';
      case PaymentApp.googlePay:
        return 'Google Pay';
      case PaymentApp.paytm:
        return 'Paytm';
      case PaymentApp.unknown:
        return 'Unknown';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentApp.phonePe:
        return Icons.phone_android;
      case PaymentApp.googlePay:
        return Icons.payment;
      case PaymentApp.paytm:
        return Icons.account_balance_wallet;
      case PaymentApp.unknown:
        return Icons.help_outline;
    }
  }

  Color get color {
    switch (this) {
      case PaymentApp.phonePe:
        return const Color(0xFF5F259F);
      case PaymentApp.googlePay:
        return const Color(0xFF4285F4);
      case PaymentApp.paytm:
        return const Color(0xFF00BAF2);
      case PaymentApp.unknown:
        return Colors.grey;
    }
  }
}

/// Model for extracted transaction data
class ExtractedTransaction {
  final String? amount;
  final String? payeeName;
  final String? date;
  final String? transactionId;
  final PaymentApp sourceApp;
  final double confidence;
  final DateTime extractionTime;

  ExtractedTransaction({
    this.amount,
    this.payeeName,
    this.date,
    this.transactionId,
    required this.sourceApp,
    required this.confidence,
    required this.extractionTime,
  });

  @override
  String toString() {
    return 'ExtractedTransaction(amount: $amount, payee: $payeeName, date: $date, app: $sourceApp, confidence: ${confidence.toStringAsFixed(1)}%)';
  }
}

/// Model for OCR text block with bounding box
class TextBlock {
  final String text;
  final BoundingBox boundingBox;
  final double confidence;
  final List<String> lines;
  final List<String> recognizedLanguages;
  final List<Point> cornerPoints;

  TextBlock({
    required this.text,
    required this.boundingBox,
    required this.confidence,
    required this.lines,
    required this.recognizedLanguages,
    required this.cornerPoints,
  });
}

/// Model for bounding box coordinates
class BoundingBox {
  final int x;
  final int y;
  final int width;
  final int height;

  BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

/// Model for point coordinates
class Point {
  final double x;
  final double y;

  Point({required this.x, required this.y});
}

/// Model for OCR result
class OcrResult {
  final List<TextBlock> textBlocks;
  final String rawText;
  final DateTime processingTime;

  OcrResult({
    required this.textBlocks,
    required this.rawText,
    required this.processingTime,
  });
}

/// Model for crop region coordinates (percentage-based)
class CropRegion {
  final double x;
  final double y;
  final double width;
  final double height;

  CropRegion({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

/// Template for payment app-specific processing
class PaymentAppTemplate {
  final PaymentApp app;
  final CropRegion cropRegion;
  final Map<String, CropRegion> fieldRegions;
  final Map<String, List<String>> fieldKeywords;

  PaymentAppTemplate({
    required this.app,
    required this.cropRegion,
    required this.fieldRegions,
    required this.fieldKeywords,
  });

  static PaymentAppTemplate getTemplate(PaymentApp app) {
    switch (app) {
      case PaymentApp.phonePe:
        return PaymentAppTemplate(
          app: app,
          cropRegion: CropRegion(x: 0.0, y: 0.1, width: 1.0, height: 0.8),
          fieldRegions: {
            'amount': CropRegion(x: 0.1, y: 0.2, width: 0.8, height: 0.3),
            'payee': CropRegion(x: 0.1, y: 0.4, width: 0.8, height: 0.2),
            'date': CropRegion(x: 0.1, y: 0.7, width: 0.8, height: 0.1),
          },
          fieldKeywords: {
            'amount': ['₹', 'Rs', 'Amount', 'Paid'],
            'payee': ['To', 'Paid to', 'Receiver', 'Name'],
            'date': ['Date', 'Time', 'On'],
          },
        );
      case PaymentApp.googlePay:
        return PaymentAppTemplate(
          app: app,
          cropRegion: CropRegion(x: 0.0, y: 0.1, width: 1.0, height: 0.8),
          fieldRegions: {
            'amount': CropRegion(x: 0.1, y: 0.15, width: 0.8, height: 0.25),
            'payee': CropRegion(x: 0.1, y: 0.45, width: 0.8, height: 0.2),
            'date': CropRegion(x: 0.1, y: 0.75, width: 0.8, height: 0.1),
          },
          fieldKeywords: {
            'amount': ['₹', 'Rs', 'Amount', 'Sent', 'Paid'],
            'payee': ['To', 'Sent to', 'Recipient', 'Name'],
            'date': ['Date', 'Time', 'Today', 'Yesterday'],
          },
        );
      case PaymentApp.paytm:
        return PaymentAppTemplate(
          app: app,
          cropRegion: CropRegion(x: 0.0, y: 0.1, width: 1.0, height: 0.8),
          fieldRegions: {
            'amount': CropRegion(x: 0.1, y: 0.2, width: 0.8, height: 0.3),
            'payee': CropRegion(x: 0.1, y: 0.4, width: 0.8, height: 0.2),
            'date': CropRegion(x: 0.1, y: 0.7, width: 0.8, height: 0.1),
          },
          fieldKeywords: {
            'amount': ['₹', 'Rs', 'Amount', 'Paid'],
            'payee': ['To', 'Paid to', 'Merchant', 'Name'],
            'date': ['Date', 'Time', 'On'],
          },
        );
      case PaymentApp.unknown:
        return PaymentAppTemplate(
          app: app,
          cropRegion: CropRegion(x: 0.0, y: 0.0, width: 1.0, height: 1.0),
          fieldRegions: {},
          fieldKeywords: {},
        );
    }
  }
}
