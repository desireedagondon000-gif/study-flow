import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import 'landing_page.dart';
import 'dashboard_page.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    // The splash page handles its own timer. No external provider needed.
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      final user = ref.read(authProvider);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              user != null ? const DashboardPage() : const LandingPage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFE1F5FE),
                border: Border.all(width: 4, color: Colors.black),
              ),
              child: const Icon(
                Icons.dashboard_customize,
                size: 80,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 60),
            const CircularProgressIndicator(
              color: Colors.black,
              strokeWidth: 4,
            ),
          ],
        ),
      ),
    );
  }
}
