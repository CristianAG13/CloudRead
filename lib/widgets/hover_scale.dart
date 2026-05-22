import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Wraps a child with a smooth hover lift (desktop/web) and a subtle press
/// shrink (touch), plus an optional accent glow on hover. Uses transform-based
/// scaling so it never shifts surrounding layout.
class HoverScale extends StatefulWidget {
  final Widget child;
  final double hoverScale;
  final double pressScale;
  final BorderRadius? glowRadius;
  final bool glow;

  const HoverScale({
    super.key,
    required this.child,
    this.hoverScale = 1.05,
    this.pressScale = 0.97,
    this.glowRadius,
    this.glow = true,
  });

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed
        ? widget.pressScale
        : _hover
            ? widget.hoverScale
            : 1.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: widget.glowRadius,
              boxShadow: (_hover && widget.glow) ? AppColors.accentGlow() : const [],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
