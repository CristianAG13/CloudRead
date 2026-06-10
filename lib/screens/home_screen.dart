import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../helpers/responsive.dart';
import '../providers/books_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/nav_controller.dart';
import '../providers/theme_provider.dart';
import '../models/book.dart';
import '../widgets/book_carousel.dart';
import '../widgets/category_chips.dart';
import '../widgets/featured_hero.dart';
import '../widgets/error_widget.dart';
import '../widgets/shimmer_loading.dart';
import 'book_detail_screen.dart';
import 'category_screen.dart';

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
      if (provider.homeState == LoadingState.idle) {
        provider.loadHome();
      }
    });
  }

  void _openDetail(Book book) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
    );
  }

  void _openCategory(String subject, String label) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CategoryScreen(subject: subject, label: label)),
    );
  }

  /// Toggle favorite and jump to the Favorites tab when a book is added.
  Future<void> _toggleFavorite(Book book) async {
    final added = await context.read<FavoritesProvider>().toggleFavorite(book);
    if (added && mounted) {
      context.read<NavController>().goToFavorites();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BooksProvider>();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _buildBody(context, provider),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BooksProvider provider) {
    switch (provider.homeState) {
      case LoadingState.idle:
      case LoadingState.loading:
        return Column(
          children: [
            _TopBar(onShuffle: provider.loadHome),
            const _SearchBarButton(),
            const Expanded(child: ShimmerHomeLoading()),
          ],
        );

      case LoadingState.error:
        return Column(
          children: [
            _TopBar(onShuffle: provider.loadHome),
            Expanded(
              child: AppErrorWidget(
                message: provider.errorMessage,
                onRetry: provider.loadHome,
              ),
            ),
          ],
        );

      case LoadingState.loaded:
        final posterWidth = Responsive.posterWidth(context);
        return Selector<FavoritesProvider, Set<String>>(
          selector: (_, f) => f.favorites.map((b) => b.key).toSet(),
          builder: (ctx, favoriteKeys, _) => Center(
            child: SizedBox(
              width: Responsive.maxContentWidth(context),
              child: RefreshIndicator(
                color: Theme.of(ctx).colorScheme.primary,
                backgroundColor: Theme.of(ctx).colorScheme.surfaceContainer,
                onRefresh: provider.loadHome,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _TopBar(onShuffle: provider.loadHome)),
                    const SliverToBoxAdapter(child: _SearchBarButton()),
                    if (provider.featured != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: FeaturedHero(
                            book: provider.featured!,
                            isFavorite: favoriteKeys.contains(provider.featured!.key),
                            onTap: () => _openDetail(provider.featured!),
                            onToggleFavorite: () => _toggleFavorite(provider.featured!),
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Text(
                          'Browse by category',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: CategoryChips(
                        categories: provider.categories,
                        onSelected: _openCategory,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    SliverList.builder(
                      itemCount: provider.shelves.length,
                      itemBuilder: (context, index) {
                        final shelf = provider.shelves[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 28),
                          child: BookCarousel(
                            title: shelf.label,
                            books: shelf.books,
                            favoriteKeys: favoriteKeys,
                            posterWidth: posterWidth,
                            onBookTap: _openDetail,
                            onToggleFavorite: _toggleFavorite,
                            onSeeAll: () => _openCategory(shelf.subject, shelf.label),
                          ),
                        );
                      },
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  ],
                ),
              ),
            ),
          ),
        );
    }
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onShuffle;

  const _TopBar({required this.onShuffle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Icon(Icons.menu_book_rounded, color: theme.colorScheme.primary, size: 26),
          const SizedBox(width: 8),
          Text(
            'CloudRead',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          Consumer<ThemeProvider>(
            builder: (_, tp, _) => IconButton(
              tooltip: 'Toggle theme',
              onPressed: tp.toggle,
              icon: Icon(tp.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            ),
          ),
          IconButton(
            tooltip: 'Shuffle shelves',
            onPressed: onShuffle,
            icon: const Icon(Icons.shuffle_rounded),
          ),
        ],
      ),
    );
  }
}

class _SearchBarButton extends StatelessWidget {
  const _SearchBarButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Material(
        color: colors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: colors.outline),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => context.read<NavController>().goTo(NavController.search),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.search, color: colors.onSurfaceVariant, size: 22),
                const SizedBox(width: 12),
                Text(
                  'Search millions of books...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
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
