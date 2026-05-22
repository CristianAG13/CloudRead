import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../models/book.dart';
import '../theme/app_theme.dart';
import '../widgets/book_grid.dart';
import '../widgets/empty_state.dart';
import 'book_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Book> _filtered = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().loadFavorites();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final provider = context.read<FavoritesProvider>();
      if (query.trim().isEmpty) {
        setState(() {
          _filtered = provider.favorites;
          _isSearching = false;
        });
      } else {
        final results = await provider.searchFavorites(query);
        if (mounted) {
          setState(() {
            _filtered = results;
            _isSearching = true;
          });
        }
      }
    });
  }

  void _clearSearch(FavoritesProvider provider) {
    _searchController.clear();
    setState(() {
      _filtered = provider.favorites;
      _isSearching = false;
    });
  }

  void _openDetail(Book book) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<FavoritesProvider>();
    final favoriteKeys = provider.favorites.map((b) => b.key).toSet();

    final displayBooks =
        _isSearching ? _filtered : provider.favorites;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'My Library',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (provider.favorites.isNotEmpty)
                    Text(
                      '${provider.favorites.length}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search in your library...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _clearSearch(provider),
                        )
                      : null,
                ),
              ),
            ),
            Expanded(
              child: _buildContent(provider, favoriteKeys, displayBooks),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    FavoritesProvider provider,
    Set<String> favoriteKeys,
    List<Book> displayBooks,
  ) {
    if (provider.favorites.isEmpty && !_isSearching) {
      return const EmptyState(
        icon: Icons.auto_stories_rounded,
        title: 'Your library is empty',
        subtitle: 'Tap the heart on any book to save it here',
      );
    }

    if (displayBooks.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matches in your library',
        subtitle: 'Try a different search term',
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.surfaceHigh,
      onRefresh: provider.loadFavorites,
      child: CustomScrollView(
        slivers: [
          BookGrid(
            books: displayBooks,
            favoriteKeys: favoriteKeys,
            onBookTap: _openDetail,
            onToggleFavorite: (book) {
              provider.toggleFavorite(book);
              if (_isSearching) {
                setState(() => _filtered.removeWhere((b) => b.key == book.key));
              }
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}
