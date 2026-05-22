import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/books_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/nav_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/book_cover.dart';
import '../widgets/gradient_button.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late Book _book;
  bool _loadingDetail = true;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final detailed = await context.read<BooksProvider>().fetchDetail(_book);
    if (mounted) {
      setState(() {
        _book = detailed;
        _loadingDetail = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favorites = context.watch<FavoritesProvider>();
    final isFavorite = favorites.favorites.any((b) => b.key == _book.key);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(book: _book, isFavorite: isFavorite),
              ),
              if (_loadingDetail)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else ...[
                if (_book.description != null && _book.description!.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionHeader(title: 'Description'),
                          const SizedBox(height: 12),
                          Text(
                            _book.description!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.7,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_book.subjects.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionHeader(title: 'Categories'),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _book.subjects
                                .map((s) => Chip(
                                      label: Text(s),
                                      labelStyle: theme.textTheme.labelMedium
                                          ?.copyWith(color: AppColors.textSecondary),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _CircleButton(
                icon: Icons.arrow_back,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Book book;
  final bool isFavorite;

  const _Header({required this.book, required this.isFavorite});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: BookCover(
                url: book.coverUrlMedium,
                displayWidth: 360,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.heroScrim,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, topInset + 56, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: 170,
                  height: 255,
                  child: BookCover(
                    url: book.coverUrl,
                    displayWidth: 170,
                    borderRadius: BorderRadius.circular(16),
                    iconSize: 48,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                book.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              if (book.authorName != null) ...[
                const SizedBox(height: 6),
                Text(
                  book.authorName!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _MetaPills(book: book),
              const SizedBox(height: 18),
              _FavoriteAction(book: book, isFavorite: isFavorite),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaPills extends StatelessWidget {
  final Book book;

  const _MetaPills({required this.book});

  @override
  Widget build(BuildContext context) {
    final pills = <Widget>[];
    if (book.firstPublishYear != null) {
      pills.add(_Pill(icon: Icons.calendar_today_rounded, label: '${book.firstPublishYear}'));
    }
    if (book.numberOfPages != null) {
      pills.add(_Pill(icon: Icons.menu_book_rounded, label: '${book.numberOfPages} pages'));
    }
    if (pills.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: pills,
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _FavoriteAction extends StatelessWidget {
  final Book book;
  final bool isFavorite;

  const _FavoriteAction({required this.book, required this.isFavorite});

  Future<void> _onTap(BuildContext context) async {
    final nav = context.read<NavController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final added = await context.read<FavoritesProvider>().toggleFavorite(book);
    if (!context.mounted) return;
    if (added) {
      nav.goToFavorites();
      navigator.popUntil((route) => route.isFirst);
    } else {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Removed from your library')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: GradientButton(
        onTap: () => _onTap(context),
        solidColor: isFavorite ? AppColors.surfaceHigher : null,
        glow: !isFavorite,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(isFavorite),
                size: 20,
                color: isFavorite ? AppColors.favorite : AppColors.onAccent,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isFavorite ? 'In your library' : 'Add to library',
              style: theme.textTheme.labelLarge?.copyWith(
                color: isFavorite ? AppColors.textPrimary : AppColors.onAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
