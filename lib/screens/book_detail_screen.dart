import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';
import '../providers/books_provider.dart';
import '../providers/favorites_provider.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late Book _book;
  bool _loadingDetail = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _loadDetail();
    _checkFavorite();
  }

  Future<void> _loadDetail() async {
    final provider = context.read<BooksProvider>();
    final detailed = await provider.fetchDetail(_book);
    if (mounted) {
      setState(() {
        _book = detailed;
        _loadingDetail = false;
      });
    }
  }

  Future<void> _checkFavorite() async {
    final favProvider = context.read<FavoritesProvider>();
    final isFav = await favProvider.isFavorite(_book.key);
    if (mounted) {
      setState(() => _isFavorite = isFav);
    }
  }

  void _toggleFavorite() {
    final favProvider = context.read<FavoritesProvider>();
    favProvider.toggleFavorite(_book);
    setState(() => _isFavorite = !_isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.redAccent : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Hero ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Cover
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: _book.coverUrl,
                      width: 220,
                      height: 330,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        width: 220,
                        height: 330,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, _, _) => Container(
                        width: 220,
                        height: 330,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.menu_book, size: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    _book.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Author
                  if (_book.authorName != null)
                    Text(
                      _book.authorName!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  const SizedBox(height: 4),

                  // Year / Pages
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_book.firstPublishYear != null)
                        Text(
                          '${_book.firstPublishYear}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (_book.firstPublishYear != null && _book.numberOfPages != null)
                        const Text(' · '),
                      if (_book.numberOfPages != null)
                        Text(
                          '${_book.numberOfPages} pages',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- Description ---
            if (_loadingDetail)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (_book.description != null && _book.description!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _sectionHeader(theme, 'Description'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _book.description!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // --- Subjects ---
              if (_book.subjects.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _sectionHeader(theme, 'Subjects'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _book.subjects.map((s) {
                      return Chip(
                        label: Text(s, style: const TextStyle(fontSize: 13)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(height: 1, color: theme.colorScheme.outlineVariant),
        ),
      ],
    );
  }
}
