import 'package:flutter/material.dart';
import '../models/book.dart';
import 'book_card.dart';

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
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final book = books[index];
          return BookCard(
            book: book,
            isFavorite: favoriteKeys.contains(book.key),
            onTap: () => onBookTap(book),
            onToggleFavorite: () => onToggleFavorite(book),
          );
        },
        childCount: books.length,
      ),
    );
  }
}
