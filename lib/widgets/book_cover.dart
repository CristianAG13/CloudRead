import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

/// Centralized cover image. Decodes at display size (`cacheWidth`) so images
/// load and paint fast, fades in smoothly, and shows a lightweight shimmer
/// placeholder instead of a spinner.
class BookCover extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// Logical display width; used to cap decode resolution for performance.
  final double displayWidth;
  final double iconSize;

  const BookCover({
    super.key,
    required this.url,
    required this.displayWidth,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.iconSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
    final cacheWidth = (displayWidth * dpr).round().clamp(120, 900);

    final image = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      memCacheWidth: cacheWidth,
      maxWidthDiskCache: cacheWidth,
      fadeInDuration: const Duration(milliseconds: 250),
      fadeOutDuration: const Duration(milliseconds: 100),
      placeholderFadeInDuration: const Duration(milliseconds: 120),
      filterQuality: FilterQuality.medium,
      placeholder: (_, _) => _ShimmerBox(iconSize: iconSize),
      errorWidget: (_, _, _) => _ErrorBox(iconSize: iconSize),
    );

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}

class _ShimmerBox extends StatefulWidget {
  final double iconSize;
  const _ShimmerBox({required this.iconSize});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 - 2 * (1 - t), 0),
              end: Alignment(1 - 2 * (1 - t), 0),
              colors: const [
                AppColors.surfaceHigh,
                AppColors.surfaceHigher,
                AppColors.surfaceHigh,
              ],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
          child: child,
        );
      },
      child: Center(
        child: Icon(Icons.menu_book_rounded,
            size: widget.iconSize, color: AppColors.textMuted),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final double iconSize;
  const _ErrorBox({required this.iconSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceHigher,
      alignment: Alignment.center,
      child: Icon(Icons.menu_book_rounded, size: iconSize, color: AppColors.textMuted),
    );
  }
}
