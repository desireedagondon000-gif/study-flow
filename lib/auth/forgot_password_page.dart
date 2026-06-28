// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'login_page.dart';
import '../widgets/app_header.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  late final TextEditingController emailController;
  late final TextEditingController newPasswordController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    newPasswordController = TextEditingController();
  }

  // --- REUSABLE HOVER BUTTONS ---

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

  Widget _hoverTextButton(String text, VoidCallback onPressed) {
    return _HoverScaleButton(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _neoInput(
    TextEditingController controller,
    String label,
    bool isPassword,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(width: 3, color: Colors.black)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF5),
      appBar: const AppHeader(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          // --- UPDATED: ConstrainedBox to prevent excessive width ---
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                const Text(
                  "RESET PASSWORD",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(width: 3, color: Colors.black),
                  ),
                  child: Column(
                    children: [
                      _neoInput(emailController, "EMAIL ADDRESS", false),
                      const SizedBox(height: 20),
                      _neoInput(newPasswordController, "NEW PASSWORD", true),
                      const SizedBox(height: 30),
                      _neoButton(
                        isLoading ? "RESETTING..." : "RESET PASSWORD",
                        isLoading ? () {} : _handleResetPassword,
                        const Color(0xFFE0F7FA),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _hoverTextButton("NEVERMIND", () => Navigator.pop(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleResetPassword() async {
    final currentContext = context;
    setState(() => isLoading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .resetPassword(
            emailController.text.trim(),
            newPasswordController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text("Password changed! You can now log in."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(currentContext).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }
}

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
