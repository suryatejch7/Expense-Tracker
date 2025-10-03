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
        url: 'https://rtiukmndzmczlziqevjq.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ0aXVrbW5kem1jemx6aXFldmpxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk0OTUzOTMsImV4cCI6MjA3NTA3MTM5M30.RzyIWaIJhyj6SBtFgfulmgTI14hyjSaxgULDhoHKQn0',
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
