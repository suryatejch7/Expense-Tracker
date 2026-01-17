import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for initializing Supabase
class SupabaseInitService {
  static bool _isInitialized = false;

  /// Initialize Supabase for the expense tracker
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load environment variables
      await dotenv.load(fileName: '.env');

      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (supabaseUrl == null || supabaseAnonKey == null) {
        throw Exception('Missing Supabase credentials in .env file');
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
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
