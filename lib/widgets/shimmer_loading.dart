import 'package:flutter/material.dart';

class ShimmerLoading extends StatefulWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0xFF2B2833),
            Color(0xFF3D3846),
            Color(0xFF2B2833),
          ],
          stops: [
            0.0,
            _controller.value,
            1.0,
          ],
        ).createShader(bounds),
        child: child!,
      ),
      child: widget.child,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double? height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

Widget _shimmerRow(int count, double itemWidth, double itemHeight,
    {double spacing = 14}) {
  return SizedBox(
    height: itemHeight,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: count,
      clipBehavior: Clip.none,
      separatorBuilder: (_, _) => SizedBox(width: spacing),
      itemBuilder: (_, _) => ShimmerBox(
        width: itemWidth,
        height: itemHeight,
        borderRadius: 12,
      ),
    ),
  );
}

class ShimmerHomeLoading extends StatelessWidget {
  const ShimmerHomeLoading({super.key});

  @override
  Widget build(BuildContext context) {
    const posterWidth = 132.0;
    final rowHeight = posterWidth * 1.5 + 64;

    return ShimmerLoading(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Featured hero placeholder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ShimmerBox(height: 220, borderRadius: 16),
            ),
            const SizedBox(height: 28),
            // Category chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: ShimmerBox(
                height: 14,
                width: 160,
                borderRadius: 4,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(
                  5,
                  (_) => ShimmerBox(
                    width: 80,
                    height: 32,
                    borderRadius: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
            // Carousel rows
            ...List.generate(4, (_) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: ShimmerBox(width: 120, height: 18, borderRadius: 4),
                    ),
                    _shimmerRow(6, posterWidth, rowHeight - 24),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class ShimmerGridLoading extends StatelessWidget {
  const ShimmerGridLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          children: [
            // Title placeholder
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ShimmerBox(width: 100, height: 16, borderRadius: 4),
              ),
            ),
            // Grid of shimmer cards
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 190,
                  childAspectRatio: 0.52,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 18,
                ),
                itemCount: 6,
                itemBuilder: (_, _) => ShimmerBox(borderRadius: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
