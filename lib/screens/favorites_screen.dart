import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../models/book.dart';
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
  List<Book> _filteredFavorites = [];
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
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final provider = context.read<FavoritesProvider>();
      if (query.trim().isEmpty) {
        setState(() {
          _filteredFavorites = provider.favorites;
          _isSearching = false;
        });
      } else {
        final results = await provider.searchFavorites(query);
        if (mounted) {
          setState(() {
            _filteredFavorites = results;
            _isSearching = true;
          });
        }
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
    final favoritesProvider = context.watch<FavoritesProvider>();
    final favoriteKeys = favoritesProvider.favorites.map((b) => b.key).toSet();

    final displayBooks = _searchController.text.trim().isEmpty
        ? favoritesProvider.favorites
        : _filteredFavorites;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          favoritesProvider.favorites.isEmpty
              ? 'My Library'
              : 'My Library (${favoritesProvider.favorites.length})',
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search within favorites
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search in your library...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _filteredFavorites = favoritesProvider.favorites;
                            _isSearching = false;
                          });
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

          // Content
          Expanded(
            child: favoritesProvider.favorites.isEmpty && !_isSearching
                ? const EmptyState(
                    icon: Icons.auto_stories,
                    title: 'Your library is empty',
                    subtitle: 'Tap the ♥ icon on any book to save it here',
                  )
                : displayBooks.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off,
                        title: 'No matches in your library',
                        subtitle: 'Try a different search term',
                      )
                    : RefreshIndicator(
                        onRefresh: () => favoritesProvider.loadFavorites(),
                        child: CustomScrollView(
                          slivers: [
                            BookGrid(
                              books: displayBooks,
                              favoriteKeys: favoriteKeys,
                              onBookTap: _navigateToDetail,
                              onToggleFavorite: (book) {
                                favoritesProvider.toggleFavorite(book);
                              },
                            ),
                            const SliverToBoxAdapter(child: SizedBox(height: 16)),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
