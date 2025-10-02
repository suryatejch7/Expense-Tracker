// Receipt types and templates for OCR processing

enum ReceiptType {
  googlePayDetailed, // Google Pay with transaction details (pasted_image_3.png)
  googlePayClean,   // Clean Google Pay with large amount display
  unknown
}

// Simple template for amount extraction only
class AmountTemplate {
  final ReceiptType type;
  final String name;
  final RegExp identifierPattern;
  final Map<String, double> cropBounds;
  final List<RegExp> amountPatterns;

  const AmountTemplate({
    required this.type,
    required this.name,
    required this.identifierPattern,
    required this.cropBounds,
    required this.amountPatterns,
  });
}
