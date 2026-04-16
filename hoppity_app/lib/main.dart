import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'widgets/responsive_wrapper.dart';

// Supabase project: wenhudcyvlhilpgazylg (ap-south-1)
// The anon key is intentionally public — it is safe to embed.
// Row-level security policies in Supabase enforce all data access rules.
const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://wenhudcyvlhilpgazylg.supabase.co',
);
const _supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indlbmh1ZGN5dmxoaWxwZ2F6eWxnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk0OTY0MTgsImV4cCI6MjA4NTA3MjQxOH0.Jdx993pFvb0JC87NaYhOQ6UR_7UIJBA1mkFQUeoK7bA',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait only on mobile — web allows all orientations
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  runApp(const HoppityApp());
}

class HoppityApp extends StatelessWidget {
  const HoppityApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    return MaterialApp(
      title: 'Hoppity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      builder: AppResponsiveBuilder.build,
      scrollBehavior: kIsWeb ? _WebScrollBehavior() : null,
      home: session != null ? const HomeScreen() : const WelcomeScreen(),
    );
  }
}

class _WebScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context, Widget child, ScrollableDetails details) => child;
}
