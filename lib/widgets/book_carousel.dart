import 'package:flutter/material.dart';
import '../models/book.dart';
import 'book_poster.dart';

/// Horizontal, lazily-built row of book posters with a section header.
class BookCarousel extends StatelessWidget {
  final String title;
  final List<Book> books;
  final Set<String> favoriteKeys;
  final void Function(Book) onBookTap;
  final void Function(Book) onToggleFavorite;
  final VoidCallback? onSeeAll;
  final double posterWidth;

  const BookCarousel({
    super.key,
    required this.title,
    required this.books,
    required this.favoriteKeys,
    required this.onBookTap,
    required this.onToggleFavorite,
    this.onSeeAll,
    this.posterWidth = 132,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Poster + title + author ≈ posterWidth * 1.5 + text lines.
    final rowHeight = posterWidth * 1.5 + 64;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text('See all'),
                ),
            ],
          ),
        ),
        SizedBox(
          height: rowHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: books.length,
            clipBehavior: Clip.none,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final book = books[index];
              return BookPoster(
                key: ValueKey(book.key),
                book: book,
                width: posterWidth,
                isFavorite: favoriteKeys.contains(book.key),
                onTap: () => onBookTap(book),
                onToggleFavorite: () => onToggleFavorite(book),
              );
            },
          ),
        ),
      ],
    );
  }
}
