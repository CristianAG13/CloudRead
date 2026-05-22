import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/books_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/nav_controller.dart';
import '../models/book.dart';
import '../theme/app_theme.dart';
import '../widgets/book_grid.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'book_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  static const _suggestions = [
    'Harry Potter',
    'Tolkien',
    'Science fiction',
    'Agatha Christie',
    'Romance',
    'Stephen King',
    'Philosophy',
    'Gabriel García Márquez',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {}); // refresh clear button
    _debounce?.cancel();
    if (query.trim().length >= 2) {
      _debounce = Timer(const Duration(milliseconds: 400), () {
        context.read<BooksProvider>().searchBooks(query);
      });
    } else if (query.isEmpty) {
      context.read<BooksProvider>().clearSearch();
    }
  }

  void _runSuggestion(String term) {
    _searchController.text = term;
    setState(() {});
    context.read<BooksProvider>().searchBooks(term);
    FocusScope.of(context).unfocus();
  }

  void _openDetail(Book book) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
    );
  }

  Future<void> _toggleFavorite(Book book) async {
    final added = await context.read<FavoritesProvider>().toggleFavorite(book);
    if (added && mounted) {
      context.read<NavController>().goToFavorites();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BooksProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final favoriteKeys = favorites.favorites.map((b) => b.key).toSet();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                'Search',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: (q) {
                  if (q.trim().isNotEmpty) {
                    context.read<BooksProvider>().searchBooks(q);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Title, author or keyword...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            provider.clearSearch();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),
            Expanded(
              child: _buildResults(provider, favoriteKeys),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(
    BooksProvider provider,
    Set<String> favoriteKeys,
  ) {
    // Idle — show suggestion chips.
    if (provider.searchState == LoadingState.idle && provider.currentQuery.isEmpty) {
      return _Suggestions(terms: _suggestions, onTap: _runSuggestion);
    }

    if (provider.searchState == LoadingState.loading) {
      return const LoadingWidget(message: 'Searching...');
    }

    if (provider.searchState == LoadingState.error) {
      return AppErrorWidget(
        message: provider.errorMessage,
        onRetry: () => provider.searchBooks(provider.currentQuery),
      );
    }

    if (provider.searchResults.isEmpty) {
      return const _MessageState(
        icon: Icons.search_off_rounded,
        title: 'No results found',
        subtitle: 'Try different keywords',
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              '${provider.searchResults.length} results',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ),
        ),
        BookGrid(
          books: provider.searchResults,
          favoriteKeys: favoriteKeys,
          onBookTap: _openDetail,
          onToggleFavorite: _toggleFavorite,
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}

class _Suggestions extends StatelessWidget {
  final List<String> terms;
  final void Function(String) onTap;

  const _Suggestions({required this.terms, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Popular searches',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: terms.map((t) {
              return ActionChip(
                label: Text(t),
                onPressed: () => onTap(t),
                backgroundColor: AppColors.surfaceHigh,
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
