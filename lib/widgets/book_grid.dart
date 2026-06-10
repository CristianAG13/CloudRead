import 'package:flutter/material.dart';
import '../helpers/responsive.dart';
import '../models/book.dart';
import 'book_card.dart';

class BookGrid extends StatelessWidget {
  final List<Book> books;
  final Set<String> favoriteKeys;
  final bool selectionMode;
  final Set<String>? selectedKeys;
  final bool staggered;
  final void Function(Book) onBookTap;
  final void Function(Book)? onBookLongPress;
  final void Function(Book) onToggleFavorite;
  final void Function(Book)? onSelectToggle;

  const BookGrid({
    super.key,
    required this.books,
    required this.favoriteKeys,
    required this.onBookTap,
    this.onBookLongPress,
    required this.onToggleFavorite,
    this.selectionMode = false,
    this.selectedKeys,
    this.staggered = false,
    this.onSelectToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: Responsive.screenPadding(context),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: Responsive.gridMaxExtent(context),
          childAspectRatio: Responsive.gridAspectRatio(context),
          crossAxisSpacing: 14,
          mainAxisSpacing: 18,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final book = books[index];
            final card = BookCard(
              key: ValueKey(book.key),
              book: book,
              isFavorite: favoriteKeys.contains(book.key),
              selectionMode: selectionMode,
              isSelected: selectedKeys?.contains(book.key) ?? false,
              onTap: () => onBookTap(book),
              onLongPress: onBookLongPress != null ? () => onBookLongPress!(book) : null,
              onToggleFavorite: () => onToggleFavorite(book),
              onSelectToggle: onSelectToggle != null ? () => onSelectToggle!(book) : null,
            );

            if (!staggered) return card;
            return _StaggerIn(index: index, child: card);
          },
          childCount: books.length,
        ),
      ),
    );
  }
}

class _StaggerIn extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggerIn({required this.index, required this.child});

  @override
  State<_StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<_StaggerIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: 45 * widget.index.clamp(0, 10));
    Future<void>.delayed(delay, () {
      if (!mounted) return;
      setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      offset: _visible ? Offset.zero : const Offset(0, 0.05),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOut,
        opacity: _visible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}
