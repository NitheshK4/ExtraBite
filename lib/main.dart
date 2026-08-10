import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/app.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Lock app strictly to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 2. Load environment variables gracefully
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // If .env is missing, app runs smoothly in local demo mode
  }

  // 3. Initialize Supabase if credentials exist
  await SupabaseService.initialize();

  // 4. Run application inside Riverpod scope
  runApp(
    const ProviderScope(
      child: ExtraBiteApp(),
    ),
  );
}
