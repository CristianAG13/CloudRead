import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Pill button with the brand accent gradient (or a solid color) and an
/// optional accent glow — used for primary CTAs.
class GradientButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final Gradient? gradient;
  final Color? solidColor;
  final bool glow;
  final EdgeInsets padding;
  final double radius;

  const GradientButton({
    super.key,
    required this.child,
    required this.onTap,
    this.gradient,
    this.solidColor,
    this.glow = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final useGradient = solidColor == null;
    final br = BorderRadius.circular(radius);

    return Material(
      color: Colors.transparent,
      borderRadius: br,
      child: Ink(
        decoration: BoxDecoration(
          gradient: useGradient ? (gradient ?? AppColors.accentGradient) : null,
          color: useGradient ? null : solidColor,
          borderRadius: br,
          boxShadow: (glow && useGradient) ? AppColors.accentGlow(alpha: 0.30, blur: 18) : null,
        ),
        child: InkWell(
          borderRadius: br,
          onTap: onTap,
          child: Padding(padding: padding, child: Center(child: child)),
        ),
      ),
    );
  }
}
