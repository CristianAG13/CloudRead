import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/book.dart';
import '../providers/favorites_provider.dart';
import '../widgets/book_cover.dart';
import '../widgets/book_grid.dart';
import '../widgets/empty_state.dart';
import '../widgets/favorite_crud_sheet.dart';
import '../widgets/favorites_filter_chips.dart';
import '../widgets/favorites_sort_menu.dart';
import '../widgets/favorites_stats_row.dart';
import 'book_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;
  bool _selectionMode = false;
  final Set<String> _selectedKeys = {};

  FavoritesProvider? _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = context.read<FavoritesProvider>();
      _provider!.loadFavorites();
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _debounce?.cancel();
    _provider?.flush();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      context.read<FavoritesProvider>().flush();
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _isSearching = query.trim().isNotEmpty);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      context.read<FavoritesProvider>().setSearchQuery(query);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _isSearching = false);
    context.read<FavoritesProvider>().setSearchQuery('');
  }

  void _openDetail(Book book) {
    if (_selectionMode) {
      _toggleSelection(book.key);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
    );
  }

  void _showCrudSheet({Book? book}) {
    final provider = context.read<FavoritesProvider>();
    FavoriteCrudSheet.show(
      context,
      bookToEdit: book,
      onSave: (updatedBook) {
        if (book == null) {
          provider.addCustomFavorite(updatedBook);
        } else {
          provider.updateFavorite(updatedBook);
        }
      },
      onDelete: book != null
          ? () {
              provider.removeFavorite(book.key);
              _showUndo();
            }
          : null,
    );
  }

  void _showUndo() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Book removed from your library'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            context.read<FavoritesProvider>().undoLastRemoval();
          },
        ),
      ),
    );
  }

  void _confirmDeleteSelected(FavoritesProvider provider) async {
    if (_selectedKeys.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete selected'),
        content: Text('Delete ${_selectedKeys.length} books from your library?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final keys = _selectedKeys.toList(growable: false);
      await provider.removeFavorites(keys);
      _clearSelection();
      _showUndo();
    }
  }

  void _shareSelected() {
    if (_selectedKeys.isEmpty) return;
    final provider = context.read<FavoritesProvider>();
    final books = provider.favorites.where((b) => _selectedKeys.contains(b.key)).toList();
    final lines = books
        .map((b) => '${b.title}${b.authorName != null ? ' — ${b.authorName}' : ''}')
        .join('\n');
    try {
      SharePlus.instance.share(ShareParams(text: lines));
    } catch (_) {}
  }

  void _exportLibrary() {
    final provider = context.read<FavoritesProvider>();
    final json = provider.exportJson();
    try {
      SharePlus.instance.share(ShareParams(text: json));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${provider.favorites.length} books exported'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _toggleSelection(String key) {
    setState(() {
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
      } else {
        _selectedKeys.add(key);
      }
      _selectionMode = _selectedKeys.isNotEmpty;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedKeys.clear();
      _selectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<FavoritesProvider>();
    final favoriteKeys = provider.favorites.map((b) => b.key).toSet();
    final displayBooks = provider.visibleFavorites;
    final totalCount = provider.favorites.length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: _selectionMode
                  ? _buildSelectionBar(theme, provider)
                  : _buildHeader(theme, provider, totalCount),
            ),
            if (!_selectionMode) ...[
              FavoritesFilterChips(
                current: provider.filter,
                onChanged: provider.setFilter,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search in your library...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isSearching
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                  ),
                ),
              ),
              if (!_isSearching && provider.favorites.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FavoritesStatsRow(
                    total: totalCount,
                    reading: provider.readingCount,
                    finished: provider.finishedCount,
                    topTag: provider.topTag,
                    averageRating: provider.averageRating,
                  ),
                ),
            ],
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
    final totalCount = provider.favorites.length;

    if (totalCount == 0 && !_isSearching) {
      return const EmptyState(
        icon: Icons.auto_stories_rounded,
        title: 'Your library is empty',
        subtitle: 'Tap the heart on any book to save it here',
      );
    }

    if (displayBooks.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matches found',
        subtitle: _isSearching ? 'Try a different search term' : 'Try a different filter',
        action: TextButton.icon(
          onPressed: () => context.read<FavoritesProvider>().setFilter(FavoritesFilter.all),
          icon: const Icon(Icons.clear_all_rounded),
          label: const Text('Clear filters'),
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;
    return RefreshIndicator(
      color: colors.primary,
      backgroundColor: colors.surfaceContainer,
      onRefresh: provider.loadFavorites,
      child: CustomScrollView(
        slivers: [
          if (!_selectionMode && !_isSearching && provider.spotlight != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: _buildSpotlightCard(provider.spotlight!, provider),
              ),
            ),
          BookGrid(
            books: displayBooks,
            favoriteKeys: favoriteKeys,
            onBookTap: _openDetail,
            onBookLongPress: (book) => _showCrudSheet(book: book),
            onToggleFavorite: (book) {
              provider.toggleFavorite(book);
              _showUndo();
            },
            selectionMode: _selectionMode,
            selectedKeys: _selectedKeys,
            staggered: !_selectionMode,
            onSelectToggle: (book) => _toggleSelection(book.key),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, FavoritesProvider provider, int totalCount) {
    return Row(
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
        if (totalCount > 0)
          Text(
            '$totalCount',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        const Spacer(),
        FavoritesSortMenu(
          current: provider.sort,
          onChanged: provider.setSort,
        ),
        IconButton(
          onPressed: totalCount == 0 ? null : _exportLibrary,
          icon: const Icon(Icons.file_download_outlined),
          tooltip: 'Export library',
        ),
        IconButton(
          onPressed: totalCount == 0
              ? null
              : () {
                  setState(() {
                    _selectionMode = true;
                    _selectedKeys.clear();
                  });
                },
          icon: const Icon(Icons.checklist_rounded),
          tooltip: 'Select books',
        ),
        IconButton(
          onPressed: () => _showCrudSheet(),
          icon: const Icon(Icons.add_circle_outline_rounded),
          tooltip: 'Add Custom Book',
        ),
      ],
    );
  }

  Widget _buildSelectionBar(ThemeData theme, FavoritesProvider provider) {
    return Row(
      children: [
        IconButton(
          onPressed: _clearSelection,
          icon: const Icon(Icons.close),
        ),
        const SizedBox(width: 8),
        Text('${_selectedKeys.length} selected', style: theme.textTheme.titleMedium),
        const Spacer(),
        IconButton(
          onPressed: _shareSelected,
          icon: const Icon(Icons.share_outlined),
          tooltip: 'Share selected',
        ),
        IconButton(
          onPressed: () => _confirmDeleteSelected(provider),
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete selected',
        ),
      ],
    );
  }

  Widget _buildSpotlightCard(Book spotlight, FavoritesProvider provider) {
    final theme = Theme.of(context);
    final total = provider.favorites.length;
    final finished = provider.finishedCount;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A202B), Color(0xFF16151A)],
        ),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 66,
                height: 96,
                child: BookCover(
                  url: spotlight.coverUrlMedium,
                  displayWidth: 66,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Library Spotlight',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    spotlight.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    spotlight.authorName ?? 'Unknown author',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaBadge(icon: Icons.favorite, text: '$total saved'),
                      _MetaBadge(
                          icon: Icons.check_circle_outline,
                          text: '$finished finished'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
