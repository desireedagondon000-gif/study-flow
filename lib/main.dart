import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth/auth_provider.dart';
import 'pages/landing_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initializing with secure local storage enabled by default in supabase_flutter
  await Supabase.initialize(
    url: 'https://rrhtwtioqhrhffphcvnt.supabase.co',
    publishableKey: 'sb_publishable_BaehXR75MNtsU_pmyYer7Q_JS5uu-Rm',
    // Supabase SDK automatically handles secure storage persistence
    // when initialized this way.
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return MaterialApp(
      title: 'Study Flow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: Stack(
        children: [
          // This stays active and watching authProvider
          // The SDK will automatically restore the session from secure storage
          user != null ? const DashboardPage() : const LandingPage(),

          // This displays over the top and removes itself after 2 seconds
          const SplashPage(),
        ],
      ),
    );
  }
}
