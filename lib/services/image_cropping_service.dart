import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/receipt_types.dart';

class ImageCroppingService {

  /// Helper method to perform the actual image cropping
  static Future<File?> performImageCrop(ui.Image image, File originalFile,
      double left, double top, double width, double height) async {
    try {
      ui.PictureRecorder recorder = ui.PictureRecorder();
      Canvas canvas = Canvas(recorder);

      canvas.drawImageRect(
        image,
        Rect.fromLTWH(left, top, width, height),
        Rect.fromLTWH(0, 0, width, height),
        Paint(),
      );

      ui.Picture picture = recorder.endRecording();
      ui.Image croppedImage = await picture.toImage(width.toInt(), height.toInt());

      ByteData? byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      Uint8List croppedBytes = byteData.buffer.asUint8List();

      String tempPath = originalFile.path.replaceAll(RegExp(r'\.(jpg|jpeg|png)'), '_smart_cropped.png');
      File croppedFile = File(tempPath);
      await croppedFile.writeAsBytes(croppedBytes);

      return croppedFile;
    } catch (e) {
      if (kDebugMode) {
        print('Error performing crop: $e');
      }
      return null;
    }
  }

  /// Smart crop using template-specific bounds
  static Future<File?> smartCropUsingTemplate(File imageFile, AmountTemplate template) async {
    try {
      Uint8List imageBytes = await imageFile.readAsBytes();
      ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      ui.FrameInfo frameInfo = await codec.getNextFrame();
      ui.Image image = frameInfo.image;

      double imageHeight = image.height.toDouble();
      double imageWidth = image.width.toDouble();

      // Use template-specific crop bounds
      double cropLeft = imageWidth * template.cropBounds['left']!;
      double cropTop = imageHeight * template.cropBounds['top']!;
      double cropRight = imageWidth * template.cropBounds['right']!;
      double cropBottom = imageHeight * template.cropBounds['bottom']!;

      double cropWidth = cropRight - cropLeft;
      double cropHeight = cropBottom - cropTop;

      if (kDebugMode) {
        print('Cropping with ${template.name} bounds: '
            'left: ${template.cropBounds['left']}, '
            'top: ${template.cropBounds['top']}, '
            'right: ${template.cropBounds['right']}, '
            'bottom: ${template.cropBounds['bottom']}');
      }

      return await performImageCrop(image, imageFile, cropLeft, cropTop, cropWidth, cropHeight);

    } catch (e) {
      if (kDebugMode) {
        print('Error in template-based crop: $e');
      }
      return null;
    }
  }
}
