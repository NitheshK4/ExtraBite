import 'app_config.dart';

/// Legacy alias forwarding to [AppConfig].
class SupabaseConfig {
  const SupabaseConfig._();

  static String get url => AppConfig.supabaseUrl;
  static String get anonKey => AppConfig.supabaseAnonKey;
  static void validate() => AppConfig.validate();
}
