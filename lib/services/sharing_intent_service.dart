import 'dart:io';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../screens/transaction_scanner_screen.dart';
import 'dart:async';

/// Service for handling shared images from other apps for OCR processing
class SharingIntentService {
  static bool _isInitialized = false;
  static StreamSubscription? _intentDataStreamSubscription;

  /// Initialize sharing intent listeners
  static void initializeSharingListeners(BuildContext context) {
    if (_isInitialized) return;
    _isInitialized = true;

    // For shared images when app is cold started
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        debugPrint('Received initial shared media: ${value.length} files');
        // Use post frame callback to ensure context is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            _handleSharedMedia(context, value.first);
          }
        });
      }
    }).catchError((err) {
      debugPrint('Error getting initial media: $err');
    });

    // For shared images when app is already running
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        if (value.isNotEmpty) {
          debugPrint('Received shared media stream: ${value.length} files');
          // Use post frame callback to ensure context is ready
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              _handleSharedMedia(context, value.first);
            }
          });
        }
      },
      onError: (err) {
        debugPrint('Error in media stream: $err');
      },
    );
  }

  /// Handle shared media file (transaction screenshot)
  static void _handleSharedMedia(BuildContext context, SharedMediaFile sharedFile) {
    try {
      debugPrint('Processing shared file: ${sharedFile.path}');

      final imageFile = File(sharedFile.path);

      if (!imageFile.existsSync()) {
        throw Exception('Shared image file not found at path: ${sharedFile.path}');
      }

      // Check if it's an image file
      final extension = sharedFile.path.toLowerCase();
      if (!extension.endsWith('.jpg') &&
          !extension.endsWith('.jpeg') &&
          !extension.endsWith('.png')) {
        throw Exception('Only image files (JPG, JPEG, PNG) are supported for transaction scanning');
      }

      // Navigate to transaction scanner with the shared image
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TransactionScannerScreen(
                initialImage: imageFile,
              ),
            ),
          );

          // Show informative message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '📱 Transaction screenshot received! Select the payment app to start processing.',
              ),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('Error handling shared media: $e');
      // Show error message if image processing fails
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to process shared screenshot: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    }
  }

  /// Dispose of resources when no longer needed
  static void dispose() {
    _intentDataStreamSubscription?.cancel();
    _intentDataStreamSubscription = null;
    _isInitialized = false;
  }
}
