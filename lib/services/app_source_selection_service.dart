import 'package:flutter/material.dart';
import '../models/transaction_ocr_models.dart';

/// Service for handling app source selection (PhonePe vs Google Pay)
class AppSourceSelectionService {

  /// Show dialog to select payment app source
  static Future<PaymentApp?> showAppSelectionDialog(BuildContext context) async {
    return await showDialog<PaymentApp>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Select Payment App',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Which app was used for this transaction?',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              _buildAppOption(
                context,
                PaymentApp.phonePe,
                'PhonePe',
                '💜',
                Colors.purple,
              ),
              const SizedBox(height: 12),
              _buildAppOption(
                context,
                PaymentApp.googlePay,
                'Google Pay',
                '🔵',
                Colors.blue,
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildAppOption(
    BuildContext context,
    PaymentApp app,
    String name,
    String emoji,
    Color color,
  ) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(app),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 16),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
