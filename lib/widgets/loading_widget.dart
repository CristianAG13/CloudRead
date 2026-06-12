import 'package:flutter/material.dart';

class LoadingWidget extends StatefulWidget {
  final String message;

  const LoadingWidget({super.key, this.message = 'Loading books...'});

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Elegant pulsating circular indicator instead of broken tween
          ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.15).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: theme.colorScheme.primary.withValues(alpha: 0.9),
              size: 42,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
