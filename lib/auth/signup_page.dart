// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import '../widgets/app_header.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final TextEditingController confirmPasswordController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
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

  // --- UI COMPONENTS ---

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
          // --- UPDATED: ConstrainedBox to limit width ---
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                const Text(
                  "SIGN UP",
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
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
                      _neoInput(passwordController, "PASSWORD", true),
                      const SizedBox(height: 20),
                      _neoInput(
                        confirmPasswordController,
                        "CONFIRM PASSWORD",
                        true,
                      ),
                      const SizedBox(height: 30),
                      _neoButton(
                        isLoading ? "CREATING..." : "REGISTER",
                        isLoading ? () {} : _handleSignUp,
                        const Color(0xFFFFF9C4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _hoverTextButton(
                  "ALREADY HAVE AN ACCOUNT?",
                  () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignUp() async {
    final currentContext = context;
    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => isLoading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text("Account created! Please log in."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(currentContext);
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
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}

// Hover Helper
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
