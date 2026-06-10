import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reading_status.dart';
import '../providers/favorites_provider.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>().favorites;
    final total = favorites.length;

    if (total == 0) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bar_chart_rounded,
                    size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text(
                  'No stats yet',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add some favorites to see your reading stats',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Text(
                  'Your Library',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _SummaryCard(
                total: total,
                readCount:
                    favorites.where((b) => b.readingStatus == ReadingStatus.finished).length,
                readingCount:
                    favorites.where((b) => b.readingStatus == ReadingStatus.reading).length,
                toReadCount:
                    favorites.where((b) => b.readingStatus == ReadingStatus.toRead).length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: _MonthlyChart(favorites: favorites),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: _RecentBooks(favorites: favorites),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int total;
  final int readCount;
  final int readingCount;
  final int toReadCount;

  const _SummaryCard({
    required this.total,
    required this.readCount,
    required this.readingCount,
    required this.toReadCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              _StatTile(
                icon: Icons.menu_book_rounded,
                iconColor: AppColors.accent,
                value: '$total',
                label: 'Total',
              ),
              const SizedBox(width: 12),
              _StatTile(
                icon: Icons.check_circle_rounded,
                iconColor: Colors.greenAccent,
                value: '$readCount',
                label: 'Read',
              ),
              const SizedBox(width: 12),
              _StatTile(
                icon: Icons.auto_stories_rounded,
                iconColor: AppColors.accentSoft,
                value: '$readingCount',
                label: 'Reading',
              ),
              const SizedBox(width: 12),
              _StatTile(
                icon: Icons.bookmark_rounded,
                iconColor: Colors.blueAccent,
                value: '$toReadCount',
                label: 'To read',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  final List favorites;

  const _MonthlyChart({required this.favorites});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final monthly = <String, int>{};

    for (int i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      monthly[key] = 0;
    }

    for (final book in favorites) {
      final added = book.addedAt;
      if (added == null) continue;
      final key = '${added.year}-${added.month.toString().padLeft(2, '0')}';
      if (monthly.containsKey(key)) {
        monthly[key] = monthly[key]! + 1;
      }
    }

    final maxVal = monthly.values.fold(0, (a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Books added per month',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: monthly.entries.map((e) {
                  final ratio = maxVal > 0 ? e.value / maxVal : 0.0;
                  final height = (ratio * 80).clamp(4.0, 80.0);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (e.value > 0)
                            Text(
                              '${e.value}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 9,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              gradient: AppColors.accentGradient,
                              borderRadius:
                                  const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            e.key.split('-')[1],
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentBooks extends StatelessWidget {
  final List favorites;

  const _RecentBooks({required this.favorites});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = List.from(favorites)
      ..sort((a, b) {
        if (a.addedAt == null && b.addedAt == null) return 0;
        if (a.addedAt == null) return 1;
        if (b.addedAt == null) return -1;
        return b.addedAt!.compareTo(a.addedAt!);
      });
    final recent = sorted.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Recently added',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: List.generate(recent.length, (i) {
                final book = recent[i];
                final hasDivider = i < recent.length - 1;
                return Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        book.readingStatus == ReadingStatus.finished
                            ? Icons.check_circle_rounded
                            : book.readingStatus == ReadingStatus.reading
                                ? Icons.auto_stories_rounded
                                : Icons.bookmark_rounded,
                        color: book.readingStatus == ReadingStatus.finished
                            ? Colors.greenAccent
                            : book.readingStatus == ReadingStatus.reading
                                ? AppColors.accentSoft
                                : Colors.blueAccent,
                        size: 20,
                      ),
                      title: Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: book.addedAt != null
                          ? Text(
                              '${book.addedAt!.day}/${book.addedAt!.month}/${book.addedAt!.year}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          : null,
                    ),
                    if (hasDivider)
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: theme.colorScheme.outline,
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
