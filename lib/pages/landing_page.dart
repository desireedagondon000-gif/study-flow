// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/app_header.dart';
import '../auth/auth_provider.dart';
import '../auth/login_page.dart';
import '../auth/signup_page.dart';
import 'dashboard_page.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  // Soft Brutalist Button Helper with integrated hover animation
  Widget _neoButton(String text, VoidCallback onPressed, Color color) {
    return _HoverScaleButton(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          border: Border.all(width: 3, color: Colors.black),
          boxShadow: const [
            BoxShadow(offset: Offset(4, 4), color: Colors.black),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final isLoggedIn = user != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5),
      appBar: AppHeader(
        actions: isLoggedIn
            ? _neoButton(
                "LOG OUT",
                () => _handleLogout(context),
                const Color(0xFFFFCDD2),
              )
            : Row(
                children: [
                  _neoButton(
                    "LOG IN",
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    ),
                    Colors.white,
                  ),
                  const SizedBox(width: 20),
                  _neoButton(
                    "SIGN UP",
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupPage()),
                    ),
                    const Color(0xFFFFF9C4),
                  ),
                ],
              ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE1F5FE),
                border: Border.all(width: 3, color: Colors.black),
              ),
              child: const Icon(
                Icons.dashboard_customize,
                size: 80,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "STUDY FLOW",
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Text(
                "ORGANIZE TASKS. STREAMLINE WORKFLOW. STAY PRODUCTIVE.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            // Primary Call to Action
            if (!isLoggedIn)
              _neoButton(
                "GET STARTED",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupPage()),
                ),
                const Color(0xFFFFF9C4),
              ),
            if (isLoggedIn)
              _neoButton(
                "GO TO DASHBOARD",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardPage()),
                ),
                const Color(0xFFB2DFDB),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await ref.read(authProvider.notifier).signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingPage()),
        (route) => false,
      );
    }
  }
}

// Wrapper to handle hover scaling logic
class _HoverScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _HoverScaleButton({required this.child, required this.onTap});

  @override
  State<_HoverScaleButton> createState() => _HoverScaleButtonState();
}

class _HoverScaleButtonState extends State<_HoverScaleButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: widget.child,
        ),
      ),
    );
  }
}
