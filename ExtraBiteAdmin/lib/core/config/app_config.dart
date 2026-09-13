import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized Production & Development Configuration for ExtraBite Admin.
///
/// Retrieves Supabase endpoint URLs and publishable client keys using
/// compile-time Dart defines (`--dart-define`), with fallback to the verified
/// ExtraBite production Supabase instance.
class AppConfig {
  const AppConfig._();

  /// The active Supabase Project URL.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://epcurxrrnbqqwifrcrjz.supabase.co',
  );

  /// The public/anonymous client key for Supabase access.
  /// (Strictly guarded by database Row Level Security and RPC policies).
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_WA8fwLpcrfoNIYjvqzVuzw_NgozUw61',
  );

  /// Current environment name ('production', 'development', 'staging').
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  );

  static bool get isProduction => environment.toLowerCase() == 'production';
  static bool get isDevelopment => environment.toLowerCase() == 'development';

  /// Validates the runtime configuration and asserts formatting requirements.
  static void validate() {
    if (supabaseUrl.isEmpty) {
      throw StateError(
        'SUPABASE_URL is missing. Provide it via compile-time definition (--dart-define=SUPABASE_URL=...) or default configuration.',
      );
    }
    if (supabaseAnonKey.isEmpty) {
      throw StateError(
        'SUPABASE_ANON_KEY is missing. Provide it via compile-time definition (--dart-define=SUPABASE_ANON_KEY=...) or default configuration.',
      );
    }
    if (!supabaseUrl.startsWith('http://') && !supabaseUrl.startsWith('https://')) {
      throw StateError('SUPABASE_URL must start with http:// or https://');
    }
  }

  /// Transforms raw exceptions into user-friendly error messages.
  static String formatErrorMessage(dynamic error) {
    if (error == null) return 'An unexpected error occurred. Please try again.';

    final str = error.toString().toLowerCase();

    if (str.contains('socketexception') ||
        str.contains('failed host lookup') ||
        str.contains('network is unreachable') ||
        str.contains('connection refused') ||
        str.contains('errno = 7')) {
      return 'Unable to connect to ExtraBite servers. Please check your network connection.';
    }

    if (error is TimeoutException || str.contains('timeoutexception') || str.contains('timed out')) {
      return 'Connection timed out. Please verify your connection and try again.';
    }

    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials') || msg.contains('invalid credentials')) {
        return 'Invalid email or password. Please try again.';
      }
      if (msg.contains('too many requests') || msg.contains('rate limit')) {
        return 'Too many attempts. Please wait a moment before trying again.';
      }
      return error.message;
    }

    if (error is PostgrestException) {
      if (error.code == 'PGRST116') {
        return 'Requested record was not found.';
      }
      if (error.message.toLowerCase().contains('jwt')) {
        return 'Your session has expired. Please sign in again.';
      }
      return error.message;
    }

    return error.toString();
  }
}
