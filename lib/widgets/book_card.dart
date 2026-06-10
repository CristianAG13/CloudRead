import 'package:flutter/material.dart';
import '../models/book.dart';
import '../theme/app_theme.dart';
import 'book_cover.dart';
import 'favorite_button.dart';
import 'hover_scale.dart';

/// Grid card used in Search, Favorites and category browsing.
class BookCard extends StatelessWidget {
  final Book book;
  final bool isFavorite;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onSelectToggle;

  const BookCard({
    super.key,
    required this.book,
    required this.isFavorite,
    required this.onTap,
    this.onLongPress,
    required this.onToggleFavorite,
    this.selectionMode = false,
    this.isSelected = false,
    this.onSelectToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(12);

    return GestureDetector(
      onTap: selectionMode ? onSelectToggle ?? onTap : onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                HoverScale(
                  glowRadius: radius,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Hero(
                      tag: 'book_cover_${book.key}',
                      child: BookCover(
                        url: book.coverUrlMedium,
                        displayWidth: 190,
                        borderRadius: radius,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: FavoriteButton(
                    isFavorite: isFavorite,
                    onTap: onToggleFavorite,
                  ),
                ),
                if (selectionMode)
                  Positioned.fill(
                    child: Material(
                      color: isSelected
                          ? Colors.black.withValues(alpha: 0.35)
                          : Colors.black.withValues(alpha: 0.15),
                      child: InkWell(
                        onTap: onSelectToggle,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isSelected ? AppColors.accent : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  book.authorName ?? 'Unknown author',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
