import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for initializing Supabase
class SupabaseInitService {
  static bool _isInitialized = false;

  /// Initialize Supabase for the expense tracker
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Supabase.initialize(
        url: 'https://zrxopmlrrnlgprphwpdm.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpyeG9wbWxycm5sZ3BycGh3cGRtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk0MzQ1MDYsImV4cCI6MjA3NTAxMDUwNn0.Dex1oE_UBTvf2FZNkem9KiUwtnCc420SF_kx0x8UJq8',
      );

      _isInitialized = true;
      debugPrint('✅ Supabase initialized successfully');
    } catch (e) {
      debugPrint('❌ Supabase initialization failed: $e');
      // For development, we can continue without Supabase
      // and use local storage as fallback
    }
  }

  /// Check if Supabase is properly initialized
  static bool get isInitialized => _isInitialized;

  /// Get Supabase client
  static SupabaseClient get client => Supabase.instance.client;
}
