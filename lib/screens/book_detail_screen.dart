import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Add url_launcher
import '../models/book.dart';
import '../providers/books_provider.dart';
import '../providers/favorites_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/book_cover.dart';
import '../widgets/favorite_crud_sheet.dart';
import '../widgets/gradient_button.dart';
import 'category_screen.dart';

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

  /// Opens [CategoryScreen] for the given human-readable subject label.
  /// The label is normalized to Open Library's URL format (lowercase, spaces
  /// → underscores, special characters stripped) so the query succeeds.
  void _openCategory(String label) {
    final subject = _normalizeSubject(label);
    if (subject.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryScreen(subject: subject, label: label),
      ),
    );
  }

  static String _normalizeSubject(String label) {
    return label
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r"[^a-z0-9\s_-]"), '')
        .replaceAll(RegExp(r"\s+"), '_');
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
                              color: theme.colorScheme.onSurfaceVariant,
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
                                .map((label) => ActionChip(
                                      label: Text(label),
                                      labelStyle: theme.textTheme.labelMedium
                                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _openCategory(label),
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
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.heroScrim
                    : [Colors.transparent, Colors.white.withValues(alpha: 0.85), Colors.white],
                stops: const [0.0, 0.5, 1.0],
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
                  child: Hero(
                    tag: 'book_cover_${book.key}',
                    child: BookCover(
                      url: book.coverUrl,
                      displayWidth: 340,
                      borderRadius: BorderRadius.circular(16),
                      iconSize: 48,
                    ),
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
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _MetaPills(book: book),
              const SizedBox(height: 18),
              if (book.readUrl != null) ...[
                _ReadAction(book: book),
                const SizedBox(height: 10),
              ],
              _FavoriteAction(book: book, isFavorite: isFavorite),
              if (isFavorite) ...[
                const SizedBox(height: 10),
                _RateAction(book: book),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Shown only when the book is already a favorite: opens the edit/rate sheet
/// (cover + reading status + tags + notes + rating) for this exact book.
class _RateAction extends StatelessWidget {
  final Book book;

  const _RateAction({required this.book});

  void _openSheet(BuildContext context) {
    final provider = context.read<FavoritesProvider>();
    // Use the stored favorite (it carries rating/status/tags/notes); fall back
    // to the detail book if for some reason it isn't found.
    final favorite = provider.favorites.firstWhere(
      (b) => b.key == book.key,
      orElse: () => book,
    );
    FavoriteCrudSheet.show(
      context,
      bookToEdit: favorite,
      onSave: provider.updateFavorite,
      onDelete: () => provider.removeFavorite(book.key),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _openSheet(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.onSurface,
          side: BorderSide(color: colors.outline),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(Icons.edit_note_rounded, size: 20, color: colors.primary),
        label: Text(
          'Rate & review',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Opens the embedded reader. Shown only when the work has a readable copy
/// on Internet Archive (i.e. `book.readUrl != null`).
class _ReadAction extends StatelessWidget {
  final Book book;

  const _ReadAction({required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: GradientButton(
        onTap: () async {
          final uri = Uri.parse(book.readUrl!);
          if (await canLaunchUrl(uri)) {
            // Esto abre el navegador integrado SIN salir de la app en celular,
            // o en una pestaña nueva si estás en Web / Windows
            await launchUrl(
              uri,
              mode: LaunchMode.inAppBrowserView,
            );
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories_rounded,
                size: 20, color: theme.colorScheme.onPrimary),
            const SizedBox(width: 8),
            Text(
              'Read now',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
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
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
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
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<FavoritesProvider>();
    final added = await provider.toggleFavorite(book);
    if (!context.mounted) return;
    messenger.hideCurrentSnackBar();
    if (added) {
      // Stay on this screen so the user can immediately rate/review the book
      // via the "Rate & review" button that now appears below.
      messenger.showSnackBar(const SnackBar(
        content: Text('Added to your library'),
        duration: Duration(seconds: 2),
      ));
    } else {
      messenger.showSnackBar(SnackBar(
        content: const Text('Removed from your library'),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            // Try to cancel pending remove and re-add locally.
            final cancelled = await provider.cancelPendingAction(book.key);
            if (cancelled) {
              // Re-add the book locally; toggleFavorite will enqueue an 'add'.
              await provider.toggleFavorite(book);
            }
          },
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SizedBox(
      width: double.infinity,
      child: GradientButton(
        onTap: () => _onTap(context),
        solidColor: isFavorite ? colors.surfaceContainerHighest : null,
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
                color: isFavorite ? AppColors.favorite : colors.onPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isFavorite ? 'In your library' : 'Add to library',
              style: theme.textTheme.labelLarge?.copyWith(
                color: isFavorite ? colors.onSurface : colors.onPrimary,
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
