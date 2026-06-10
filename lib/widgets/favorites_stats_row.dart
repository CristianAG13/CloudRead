import 'package:flutter/material.dart';

class FavoritesStatsRow extends StatelessWidget {
  final int total;
  final int reading;
  final int finished;
  final String? topTag;
  final double? averageRating;

  const FavoritesStatsRow({
    super.key,
    required this.total,
    required this.reading,
    required this.finished,
    this.topTag,
    this.averageRating,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _StatChip(label: '$total books', theme: theme),
          if (reading > 0) _StatChip(label: '$reading reading', theme: theme),
          if (finished > 0) _StatChip(label: '$finished finished', theme: theme),
          if (topTag != null) _StatChip(label: '#$topTag', theme: theme),
          if (averageRating != null)
            _StatChip(
              label: '${averageRating!.toStringAsFixed(1)} ★',
              theme: theme,
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _StatChip({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
