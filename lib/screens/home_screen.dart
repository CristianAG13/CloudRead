import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/books_provider.dart';
import '../providers/favorites_provider.dart';
import '../models/book.dart';
import '../widgets/book_grid.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'book_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BooksProvider>();
      if (provider.state == _HomeScreenStateName.idle) {
        provider.loadDiscoverBooks();
      }
    });
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
        title: const Text('Discover'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'Shuffle subjects',
            onPressed: () => booksProvider.loadDiscoverBooks(),
          ),
        ],
      ),
      body: _buildBody(
        booksProvider,
        favoriteKeys,
        theme,
        onToggleFavorite: (book) => favoritesProvider.toggleFavorite(book),
      ),
    );
  }

  Widget _buildBody(
    BooksProvider provider,
    Set<String> favoriteKeys,
    ThemeData theme, {
    required void Function(Book) onToggleFavorite,
  }) {
    switch (provider.state) {
      case LoadingState.idle:
      case LoadingState.loading:
        return const LoadingWidget(message: 'Curating books for you...');

      case LoadingState.error:
        return AppErrorWidget(
          message: provider.errorMessage,
          onRetry: () => provider.loadDiscoverBooks(),
        );

      case LoadingState.loaded:
        if (provider.books.isEmpty) {
          return const AppErrorWidget(
            message: 'No books found. Try again!',
            onRetry: null,
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadDiscoverBooks(),
          child: CustomScrollView(
            slivers: [
              // Subject banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Today\'s picks',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => provider.loadDiscoverBooks(),
                        icon: const Icon(Icons.shuffle, size: 18),
                        label: const Text('Shuffle'),
                      ),
                    ],
                  ),
                ),
              ),

              // Book grid
              BookGrid(
                books: provider.books,
                favoriteKeys: favoriteKeys,
                onBookTap: _navigateToDetail,
                onToggleFavorite: onToggleFavorite,
              ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        );
    }
  }
}

/// Helper enum extension to check initial state
extension _HomeScreenStateName on LoadingState {
  static const idle = LoadingState.idle;
}
