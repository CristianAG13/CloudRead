import 'package:flutter/material.dart';
import '../models/book.dart';
import 'book_card.dart';

/// Responsive sliver grid of book cards. Column count adapts to width
/// (2 on phones, more on tablet/desktop) via a max cross-axis extent.
class BookGrid extends StatelessWidget {
  final List<Book> books;
  final Set<String> favoriteKeys;
  final void Function(Book) onBookTap;
  final void Function(Book) onToggleFavorite;

  const BookGrid({
    super.key,
    required this.books,
    required this.favoriteKeys,
    required this.onBookTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 190,
          childAspectRatio: 0.52,
          crossAxisSpacing: 14,
          mainAxisSpacing: 18,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final book = books[index];
            return BookCard(
              key: ValueKey(book.key),
              book: book,
              isFavorite: favoriteKeys.contains(book.key),
              onTap: () => onBookTap(book),
              onToggleFavorite: () => onToggleFavorite(book),
            );
          },
          childCount: books.length,
        ),
      ),
    );
  }
}
