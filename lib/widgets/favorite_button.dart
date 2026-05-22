import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Circular favorite toggle with a springy "pop" animation on tap and a
/// cross-fade between the outline and filled heart.
class FavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onTap;
  final double iconSize;
  final EdgeInsets padding;
  final Color background;




  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onTap,
    this.iconSize = 16,
    this.padding = const EdgeInsets.all(7),
    this.background = const Color(0x73000000),
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.45, end: 1.0), weight: 60),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap();
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _handleTap,
        child: Padding(
          padding: widget.padding,
          child: ScaleTransition(
            scale: _scale,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(widget.isFavorite),
                size: widget.iconSize,
                color: widget.isFavorite ? AppColors.favorite : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
