import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/books_provider.dart';
import '../providers/favorites_provider.dart';
import '../models/book.dart';
import '../widgets/book_grid.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/empty_state.dart';
import 'book_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.length >= 2) {
      _debounce = Timer(const Duration(milliseconds: 400), () {
        context.read<BooksProvider>().searchBooks(query);
      });
    } else if (query.isEmpty) {
      context.read<BooksProvider>().clearSearch();
    }
  }

  void _navigateToDetail(Book book) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookDetailScreen(book: book),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booksProvider = context.watch<BooksProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final favoriteKeys = favoritesProvider.favorites.map((b) => b.key).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Search millions of books...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          booksProvider.clearSearch();
                        },
                      )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // Results
          Expanded(
            child: _buildResults(
              booksProvider,
              favoriteKeys,
              theme,
              onToggleFavorite: (book) => favoritesProvider.toggleFavorite(book),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(
    BooksProvider provider,
    Set<String> favoriteKeys,
    ThemeData theme, {
    required void Function(Book) onToggleFavorite,
  }) {
    // Idle state — show suggestions
    if (provider.searchState == LoadingState.idle && provider.currentQuery.isEmpty) {
      return EmptyState(
        icon: Icons.lightbulb_outline,
        title: 'Try searching for:',
        subtitle: 'Tap a suggestion below',
      );
    }

    // Loading
    if (provider.searchState == LoadingState.loading) {
      return const LoadingWidget(message: 'Searching...');
    }

    // Error
    if (provider.searchState == LoadingState.error) {
      return AppErrorWidget(
        message: provider.errorMessage,
        onRetry: () => provider.searchBooks(provider.currentQuery),
      );
    }

    // No results
    if (provider.searchResults.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No results found',
        subtitle: 'Try different keywords',
      );
    }

    // Results
    return RefreshIndicator(
      onRefresh: () => provider.searchBooks(provider.currentQuery),
      child: CustomScrollView(
        slivers: [
          // Result count
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '${provider.searchResults.length} results',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),

          // Grid
          BookGrid(
            books: provider.searchResults,
            favoriteKeys: favoriteKeys,
            onBookTap: _navigateToDetail,
            onToggleFavorite: onToggleFavorite,
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}
