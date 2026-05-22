import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/books_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/nav_controller.dart';
import '../models/book.dart';
import '../widgets/book_grid.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'book_detail_screen.dart';

/// Full grid for a single category, opened from Home chips or "See all".
class CategoryScreen extends StatefulWidget {
  final String subject;
  final String label;

  const CategoryScreen({super.key, required this.subject, required this.label});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BooksProvider>().loadCategory(widget.subject, widget.label);
    });
  }

  void _openDetail(Book book) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
    );
  }

  /// Toggle favorite; when adding, return to the shell and open Favorites.
  Future<void> _toggleFavorite(Book book) async {
    final added = await context.read<FavoritesProvider>().toggleFavorite(book);
    if (added && mounted) {
      context.read<NavController>().goToFavorites();
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BooksProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final favoriteKeys = favorites.favorites.map((b) => b.key).toSet();

    return Scaffold(
      appBar: AppBar(title: Text(widget.label)),
      body: _buildBody(provider, favoriteKeys),
    );
  }

  Widget _buildBody(
    BooksProvider provider,
    Set<String> favoriteKeys,
  ) {
    switch (provider.browseState) {
      case LoadingState.idle:
      case LoadingState.loading:
        return const LoadingWidget(message: 'Loading collection...');
      case LoadingState.error:
        return AppErrorWidget(
          message: provider.errorMessage,
          onRetry: () => provider.loadCategory(widget.subject, widget.label),
        );
      case LoadingState.loaded:
        if (provider.browseResults.isEmpty) {
          return const AppErrorWidget(message: 'No books in this category.');
        }
        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            BookGrid(
              books: provider.browseResults,
              favoriteKeys: favoriteKeys,
              onBookTap: _openDetail,
              onToggleFavorite: _toggleFavorite,
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
    }
  }
}
