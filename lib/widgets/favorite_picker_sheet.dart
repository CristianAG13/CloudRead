import 'package:flutter/material.dart';
import '../models/book.dart';
import 'book_cover.dart';

/// Bottom sheet that shows a horizontal carousel of the user's favorite books
/// so they can pick one to rate / review.
///
/// Returns the selected [Book] via the popped value, or `null` if the sheet
/// was dismissed without a selection.
class FavoritePickerSheet extends StatelessWidget {
  final List<Book> books;

  const FavoritePickerSheet({super.key, required this.books});

  /// Shows the picker and resolves with the chosen book (or `null`).
  static Future<Book?> show(BuildContext context, List<Book> books) {
    return showModalBottomSheet<Book>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FavoritePickerSheet(books: books),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // Cap the sheet height so it never exceeds the viewport (e.g. short
    // windows / landscape); the content scrolls vertically if it doesn't fit.
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 12, bottom: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Pick a book to review',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Choose one of your favorites to rate it',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 214,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: books.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return _PickerTile(
                        book: book,
                        onTap: () => Navigator.of(context).pop(book),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _PickerTile({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const width = 108.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: width,
              height: 150,
              child: BookCover(
                url: book.coverUrlMedium,
                displayWidth: width,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
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
    );
  }
}
