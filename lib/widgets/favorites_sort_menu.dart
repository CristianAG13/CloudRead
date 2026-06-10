import 'package:flutter/material.dart';
import '../providers/favorites_provider.dart';

class FavoritesSortMenu extends StatelessWidget {
  final FavoritesSort current;
  final ValueChanged<FavoritesSort> onChanged;

  const FavoritesSortMenu({
    super.key,
    required this.current,
    required this.onChanged,
  });

  static IconData _iconFor(FavoritesSort s) {
    switch (s) {
      case FavoritesSort.recent:
        return Icons.schedule_rounded;
      case FavoritesSort.titleAsc:
        return Icons.sort_by_alpha_rounded;
      case FavoritesSort.authorAsc:
        return Icons.person_rounded;
      case FavoritesSort.ratingDesc:
        return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<FavoritesSort>(
      onSelected: onChanged,
      tooltip: 'Sort by',
      icon: Icon(_iconFor(current), color: Theme.of(context).colorScheme.onSurfaceVariant),
      itemBuilder: (context) {
        final theme = Theme.of(context);
        return FavoritesSort.values.map((s) {
          return PopupMenuItem(
            value: s,
            child: Row(
              children: [
                Icon(
                  _iconFor(s),
                  size: 18,
                  color: s == current ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Text(
                  s.label,
                  style: TextStyle(
                    fontWeight: s == current ? FontWeight.w700 : FontWeight.w400,
                    color: s == current ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  ),
                ),
                if (s == current) ...[
                  const Spacer(),
                  Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
                ],
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
