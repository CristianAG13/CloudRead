import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String message;

  const LoadingWidget({super.key, this.message = 'Loading books...'});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Book pages flipping animation
          SizedBox(
            height: 40,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 600 + i * 150),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scaleY: 1.0 + 0.6 * (value < 0.5 ? value * 2 : 2 - value * 2),
                      child: Container(
                        width: 10,
                        height: 28,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.6 + 0.4 * (1 - value)),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  },
                  onEnd: () {},
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
