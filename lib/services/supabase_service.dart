import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static bool _isInitialized = false;

  static bool get isConfigured =>
      _isInitialized &&
      dotenv.isEveryDefined(['SUPABASE_URL', 'SUPABASE_ANON_KEY']) &&
      (dotenv.env['SUPABASE_URL']?.isNotEmpty ?? false) &&
      (dotenv.env['SUPABASE_ANON_KEY']?.isNotEmpty ?? false);

  static Future<void> initialize() async {
    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (supabaseUrl != null &&
          supabaseAnonKey != null &&
          supabaseUrl.startsWith('http') &&
          supabaseAnonKey.length > 20) {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseAnonKey,
        );
        _isInitialized = true;
        if (kDebugMode) {
          print('✅ Supabase initialized successfully.');
        }
      } else {
        if (kDebugMode) {
          print('ℹ️ Supabase credentials not found or empty. Running in standalone local Demo Mode.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Supabase init skipped: $e. Using local demo repositories.');
      }
    }
  }

  static SupabaseClient? get client {
    if (isConfigured) {
      return Supabase.instance.client;
    }
    return null;
  }
}
