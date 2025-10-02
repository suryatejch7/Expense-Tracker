import 'dart:io';
import 'package:image/image.dart' as img;
import '../models/transaction_ocr_models.dart';

/// Service for preprocessing transaction screenshots
class ImagePreprocessingService {

  /// Preprocess image based on selected payment app
  static Future<File> preprocessImage(File imageFile, PaymentApp app) async {
    try {
      // Read image
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Step 1: Crop based on app template
      image = _cropForApp(image, app);

      // Step 2: Convert to grayscale
      image = img.grayscale(image);

      // Step 3: Apply Gaussian blur then sharpen
      image = img.gaussianBlur(image, radius: 1);
      image = _sharpenImage(image);

      // Step 4: Apply binary thresholding for better OCR
      image = _applyThreshold(image);

      // Save processed image
      final processedPath = '${imageFile.parent.path}/processed_${DateTime.now().millisecondsSinceEpoch}.png';
      final processedFile = File(processedPath);
      await processedFile.writeAsBytes(img.encodePng(image));

      return processedFile;
    } catch (e) {
      throw Exception('Image preprocessing failed: $e');
    }
  }

  /// Crop image based on app-specific templates
  static img.Image _cropForApp(img.Image image, PaymentApp app) {
    final template = PaymentAppTemplate.getTemplate(app);

    // Calculate crop coordinates based on percentage
    final cropX = (image.width * template.cropRegion.x).round();
    final cropY = (image.height * template.cropRegion.y).round();
    final cropWidth = (image.width * template.cropRegion.width).round();
    final cropHeight = (image.height * template.cropRegion.height).round();

    // Ensure crop coordinates are within image bounds
    final safeX = cropX.clamp(0, image.width - 1);
    final safeY = cropY.clamp(0, image.height - 1);
    final safeWidth = cropWidth.clamp(1, image.width - safeX);
    final safeHeight = cropHeight.clamp(1, image.height - safeY);

    return img.copyCrop(image,
      x: safeX,
      y: safeY,
      width: safeWidth,
      height: safeHeight
    );
  }

  /// Apply sharpening filter
  static img.Image _sharpenImage(img.Image image) {
    // Sharpening kernel as flattened list
    final kernel = [-1, -1, -1, -1, 9, -1, -1, -1, -1];

    return img.convolution(image, filter: kernel);
  }

  /// Apply binary thresholding
  static img.Image _applyThreshold(img.Image image) {
    const threshold = 128;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = img.getLuminance(pixel);

        final newPixel = luminance > threshold
          ? img.ColorRgb8(255, 255, 255) // White
          : img.ColorRgb8(0, 0, 0);      // Black

        image.setPixel(x, y, newPixel);
      }
    }

    return image;
  }

  /// Create region-specific crops for secondary OCR
  static Future<List<File>> createRegionCrops(
    File originalImage,
    PaymentApp app,
    List<TextBlock> textBlocks
  ) async {
    final bytes = await originalImage.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Failed to decode image for region cropping');
    }

    final crops = <File>[];
    final template = PaymentAppTemplate.getTemplate(app);

    // Create specific crops for amount, payee, and date regions
    for (final region in template.fieldRegions.entries) {
      final regionName = region.key;
      final regionRect = region.value;

      // Find text blocks in this region
      final regionBlocks = _findTextBlocksInRegion(textBlocks, regionRect, image);

      if (regionBlocks.isNotEmpty) {
        // Create expanded bounding box around all blocks in region
        final boundingBox = _createExpandedBoundingBox(regionBlocks, image);

        final croppedImage = img.copyCrop(
          image,
          x: boundingBox.x,
          y: boundingBox.y,
          width: boundingBox.width,
          height: boundingBox.height,
        );

        // Apply preprocessing to the crop
        final processedCrop = _preprocessCrop(croppedImage);

        final cropPath = '${originalImage.parent.path}/crop_${regionName}_${DateTime.now().millisecondsSinceEpoch}.png';
        final cropFile = File(cropPath);
        await cropFile.writeAsBytes(img.encodePng(processedCrop));

        crops.add(cropFile);
      }
    }

    return crops;
  }

  static List<TextBlock> _findTextBlocksInRegion(
    List<TextBlock> textBlocks,
    CropRegion region,
    img.Image image
  ) {
    final regionBlocks = <TextBlock>[];

    final regionX = (image.width * region.x).round();
    final regionY = (image.height * region.y).round();
    final regionWidth = (image.width * region.width).round();
    final regionHeight = (image.height * region.height).round();

    for (final block in textBlocks) {
      final blockCenterX = block.boundingBox.x + (block.boundingBox.width / 2);
      final blockCenterY = block.boundingBox.y + (block.boundingBox.height / 2);

      if (blockCenterX >= regionX &&
          blockCenterX <= regionX + regionWidth &&
          blockCenterY >= regionY &&
          blockCenterY <= regionY + regionHeight) {
        regionBlocks.add(block);
      }
    }

    return regionBlocks;
  }

  static BoundingBox _createExpandedBoundingBox(List<TextBlock> blocks, img.Image image) {
    if (blocks.isEmpty) {
      return BoundingBox(x: 0, y: 0, width: 100, height: 50);
    }

    int minX = blocks.first.boundingBox.x;
    int minY = blocks.first.boundingBox.y;
    int maxX = blocks.first.boundingBox.x + blocks.first.boundingBox.width;
    int maxY = blocks.first.boundingBox.y + blocks.first.boundingBox.height;

    for (final block in blocks) {
      minX = (block.boundingBox.x).clamp(0, image.width);
      minY = (block.boundingBox.y).clamp(0, image.height);
      maxX = (block.boundingBox.x + block.boundingBox.width).clamp(0, image.width);
      maxY = (block.boundingBox.y + block.boundingBox.height).clamp(0, image.height);
    }

    // Add padding
    const padding = 10;
    minX = (minX - padding).clamp(0, image.width);
    minY = (minY - padding).clamp(0, image.height);
    maxX = (maxX + padding).clamp(0, image.width);
    maxY = (maxY + padding).clamp(0, image.height);

    return BoundingBox(
      x: minX,
      y: minY,
      width: maxX - minX,
      height: maxY - minY,
    );
  }

  static img.Image _preprocessCrop(img.Image crop) {
    // Enhanced preprocessing for individual crops
    crop = img.gaussianBlur(crop, radius: 1); // Use integer radius
    crop = _sharpenImage(crop);
    crop = _enhanceContrast(crop);
    return crop;
  }

  static img.Image _enhanceContrast(img.Image image) {
    const factor = 1.5;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.round();
        final g = pixel.g.round();
        final b = pixel.b.round();

        final newR = ((r - 128) * factor + 128).clamp(0, 255).round();
        final newG = ((g - 128) * factor + 128).clamp(0, 255).round();
        final newB = ((b - 128) * factor + 128).clamp(0, 255).round();

        image.setPixel(x, y, img.ColorRgb8(newR, newG, newB));
      }
    }

    return image;
  }
}
