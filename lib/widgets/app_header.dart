import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../pages/landing_page.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final Widget? actions;

  const AppHeader({super.key, this.actions});

  static const double _headerHeight = 80.0;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: _headerHeight,
      backgroundColor: const Color(0xFFFFFDF5),
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Container(color: Colors.black, height: 3),
      ),
      leadingWidth: 180, // Slightly widened to accommodate larger hover state
      leading: Center(
        child: _StudyFlowButton(
          onTap: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LandingPage()),
            (route) => false,
          ),
        ),
      ),
      actions: actions != null
          ? [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(child: actions),
              ),
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(_headerHeight + 3);
}

class _StudyFlowButton extends StatefulWidget {
  final VoidCallback onTap;
  const _StudyFlowButton({required this.onTap});

  @override
  State<_StudyFlowButton> createState() => _StudyFlowButtonState();
}

class _StudyFlowButtonState extends State<_StudyFlowButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    // Scale up slightly for both hover and press
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        if (!_isPressed) _controller.reverse();
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          if (!_isHovered) _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Colors.transparent,
            child: Text(
              "STUDYFLOW",
              style: GoogleFonts.ibmPlexMono(
                color: _isPressed ? Colors.grey[800] : Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 22, // Slightly larger base size
                letterSpacing: -1,
                shadows: [
                  Shadow(
                    color: _isPressed
                        ? Colors.transparent
                        : const Color(0xFFBDBDBD),
                    offset: _isPressed ? Offset.zero : const Offset(3, 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
