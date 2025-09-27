import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color color;
  final String? lottieAsset;
  final VoidCallback onTap;

  const AnimatedActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.lottieAsset,
  });

  @override
  State<AnimatedActionCard> createState() => _AnimatedActionCardState();
}

class _AnimatedActionCardState extends State<AnimatedActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scale = Tween<double>(begin: 1, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: Container(
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.lottieAsset != null
                  ? Lottie.asset(widget.lottieAsset!, height: 60)
                  : Icon(widget.icon, color: Colors.white, size: 40),
              const SizedBox(height: 10),
              Text(
                widget.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
