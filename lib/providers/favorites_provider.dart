import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../models/reading_status.dart';
import '../services/favorites_storage.dart';

enum FavoritesSort { recent, titleAsc, authorAsc, ratingDesc }

extension FavoritesSortLabels on FavoritesSort {
  String get label {
    switch (this) {
      case FavoritesSort.recent:
        return 'Recently added';
      case FavoritesSort.titleAsc:
        return 'Title A–Z';
      case FavoritesSort.authorAsc:
        return 'Author A–Z';
      case FavoritesSort.ratingDesc:
        return 'Highest rated';
    }
  }
}

enum FavoritesFilter { all, toRead, reading, finished }

extension FavoritesFilterLabels on FavoritesFilter {
  String get label {
    switch (this) {
      case FavoritesFilter.all:
        return 'All';
      case FavoritesFilter.toRead:
        return 'To read';
      case FavoritesFilter.reading:
        return 'Reading';
      case FavoritesFilter.finished:
        return 'Finished';
    }
  }
}

class _RemovalSnapshot {
  final List<Book> books;
  final DateTime timestamp;

  const _RemovalSnapshot({required this.books, required this.timestamp});
}

class FavoritesProvider extends ChangeNotifier {
  final FavoritesStorage _storage;

  Map<String, Book> _byKey = const {};
  List<Book> _favorites = const [];

  FavoritesSort _sort = FavoritesSort.recent;
  FavoritesFilter _filter = FavoritesFilter.all;
  String _searchQuery = '';

  bool _initialized = false;

  List<Map<String, dynamic>> _pendingActions = const [];
  bool _processingQueue = false;

  Timer? _writeTimer;
  _RemovalSnapshot? _lastRemoval;

  FavoritesProvider({FavoritesStorage? storage})
      : _storage = storage ?? SharedPreferencesFavoritesStorage();

  List<Book> get favorites => List.unmodifiable(_favorites);

  List<Book> get visibleFavorites => _computeVisible();

  FavoritesSort get sort => _sort;
  FavoritesFilter get filter => _filter;
  String get searchQuery => _searchQuery;

  bool get initialized => _initialized;

  int get authorCount =>
      _favorites.map((b) => b.authorName?.trim()).whereType<String>().where((n) => n.isNotEmpty).toSet().length;

  int get readingCount =>
      _favorites.where((b) => b.readingStatus == ReadingStatus.reading).length;

  int get finishedCount =>
      _favorites.where((b) => b.readingStatus == ReadingStatus.finished).length;

  double? get averageRating {
    final rated = _favorites.where((b) => b.personalRating != null && b.personalRating! > 0).toList();
    if (rated.isEmpty) return null;
    return rated.fold(0.0, (s, b) => s + b.personalRating!) / rated.length;
  }

  String? get topTag {
    final tagCount = <String, int>{};
    for (final b in _favorites) {
      for (final t in b.tags) {
        tagCount[t] = (tagCount[t] ?? 0) + 1;
      }
    }
    if (tagCount.isEmpty) return null;
    return tagCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  Book? get spotlight {
    if (_favorites.length < 3) return null;
    final sorted = List<Book>.of(_favorites)
      ..sort((a, b) {
        final da = a.addedAt ?? DateTime(2000);
        final db = b.addedAt ?? DateTime(2000);
        return db.compareTo(da);
      });
    return sorted.first;
  }

  bool isFavorite(String key) => _byKey.containsKey(key);

  List<Book> _computeVisible() {
    var result = List<Book>.of(_favorites);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      result = result.where((b) {
        if (b.title.toLowerCase().contains(q)) return true;
        if (b.authorName?.toLowerCase().contains(q) ?? false) return true;
        if (b.tags.any((t) => t.contains(q))) return true;
        if (b.readingStatus.name.contains(q)) return true;
        return false;
      }).toList();
    }

    switch (_filter) {
      case FavoritesFilter.all:
        break;
      case FavoritesFilter.toRead:
        result = result.where((b) => b.readingStatus == ReadingStatus.toRead).toList();
        break;
      case FavoritesFilter.reading:
        result = result.where((b) => b.readingStatus == ReadingStatus.reading).toList();
        break;
      case FavoritesFilter.finished:
        result = result.where((b) => b.readingStatus == ReadingStatus.finished).toList();
        break;
    }

    _applySort(result);
    return result;
  }

  void _applySort(List<Book> list) {
    switch (_sort) {
      case FavoritesSort.recent:
        list.sort((a, b) {
          final da = a.addedAt ?? DateTime(2000);
          final db = b.addedAt ?? DateTime(2000);
          return db.compareTo(da);
        });
        break;
      case FavoritesSort.titleAsc:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case FavoritesSort.authorAsc:
        list.sort((a, b) {
          final aa = (a.authorName ?? '').toLowerCase();
          final ba = (b.authorName ?? '').toLowerCase();
          final cmp = aa.compareTo(ba);
          if (cmp != 0) return cmp;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
        break;
      case FavoritesSort.ratingDesc:
        list.sort((a, b) {
          final ra = a.personalRating ?? 0;
          final rb = b.personalRating ?? 0;
          return rb.compareTo(ra);
        });
        break;
    }
  }

  void setSort(FavoritesSort s) {
    _sort = s;
    notifyListeners();
  }

  void setFilter(FavoritesFilter f) {
    _filter = f;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  Future<void> loadFavorites() async {
    final loaded = await _storage.load();
    _byKey = {for (final b in loaded) b.key: b};
    _favorites = loaded;
    _pendingActions = await _storage.loadPendingActions();
    _initialized = true;
    notifyListeners();
    unawaited(_processQueue());
  }

  Future<void> flush() async {
    _writeTimer?.cancel();
    _writeTimer = null;
    await _storage.save(_favorites);
  }

  Future<bool> toggleFavorite(Book book) async {
    final wasFav = _byKey.containsKey(book.key);
    if (wasFav) {
      _byKey = Map<String, Book>.of(_byKey)..remove(book.key);
      _favorites = _favorites.where((b) => b.key != book.key).toList(growable: false);
    } else {
      final enriched = book.copyWith(
        addedAt: DateTime.now().toUtc(),
        readingStatus: ReadingStatus.toRead,
      );
      _byKey = Map<String, Book>.of(_byKey)..[book.key] = enriched;
      _favorites = [enriched, ..._favorites];
    }
    notifyListeners();
    _scheduleSave();

    final action = {
      'key': book.key,
      'action': wasFav ? 'remove' : 'add',
      'ts': DateTime.now().toUtc().toIso8601String(),
    };
    _pendingActions = List<Map<String, dynamic>>.of(_pendingActions)..add(action);
    await _storage.savePendingActions(_pendingActions);
    unawaited(_processQueue());

    return !wasFav;
  }

  Future<void> removeFavorite(String key) async {
    final book = _byKey[key];
    if (book == null) return;

    _lastRemoval = _RemovalSnapshot(books: [book], timestamp: DateTime.now());

    _byKey = Map<String, Book>.of(_byKey)..remove(key);
    _favorites = _favorites.where((b) => b.key != key).toList(growable: false);
    notifyListeners();
    _scheduleSave();

    final action = {'key': key, 'action': 'remove', 'ts': DateTime.now().toUtc().toIso8601String()};
    _pendingActions = List<Map<String, dynamic>>.of(_pendingActions)..add(action);
    await _storage.savePendingActions(_pendingActions);
    unawaited(_processQueue());
  }

  Future<void> removeFavorites(List<String> keys) async {
    final keySet = keys.toSet();
    final removed = _favorites.where((b) => keySet.contains(b.key)).toList(growable: false);
    if (removed.isEmpty) return;

    _lastRemoval = _RemovalSnapshot(books: removed, timestamp: DateTime.now());

    _byKey = Map<String, Book>.of(_byKey)..removeWhere((k, _) => keySet.contains(k));
    _favorites = _favorites.where((b) => !keySet.contains(b.key)).toList(growable: false);
    notifyListeners();
    _scheduleSave();

    final now = DateTime.now().toUtc().toIso8601String();
    final actions = keys.map((k) => {'key': k, 'action': 'remove', 'ts': now}).toList();
    _pendingActions = List<Map<String, dynamic>>.of(_pendingActions)..addAll(actions);
    await _storage.savePendingActions(_pendingActions);
    unawaited(_processQueue());
  }

  bool undoLastRemoval() {
    final snap = _lastRemoval;
    if (snap == null) return false;
    if (DateTime.now().difference(snap.timestamp).inSeconds > 4) {
      _lastRemoval = null;
      return false;
    }
    for (final book in snap.books) {
      _byKey = Map<String, Book>.of(_byKey)..[book.key] = book;
      _favorites = [book, ..._favorites];
    }
    _lastRemoval = null;
    notifyListeners();
    _scheduleSave();
    return true;
  }

  Future<void> updateFavorite(Book updatedBook) async {
    final existing = _byKey[updatedBook.key];
    if (existing == null) return;

    _byKey = Map<String, Book>.of(_byKey)..[updatedBook.key] = updatedBook;
    _favorites = _favorites.map((b) => b.key == updatedBook.key ? updatedBook : b).toList(growable: false);
    notifyListeners();
    _scheduleSave();
  }

  Future<void> addCustomFavorite(Book newBook) async {
    if (_byKey.containsKey(newBook.key)) return;
    final enriched = newBook.copyWith(addedAt: DateTime.now().toUtc());
    _byKey = Map<String, Book>.of(_byKey)..[enriched.key] = enriched;
    _favorites = [enriched, ..._favorites];
    notifyListeners();
    _scheduleSave();

    final action = {'key': enriched.key, 'action': 'add', 'ts': DateTime.now().toUtc().toIso8601String()};
    _pendingActions = List<Map<String, dynamic>>.of(_pendingActions)..add(action);
    await _storage.savePendingActions(_pendingActions);
    unawaited(_processQueue());
  }

  Future<void> setReadingStatus(String key, ReadingStatus status) async {
    final book = _byKey[key];
    if (book == null) return;
    final updated = book.copyWith(readingStatus: status);
    _byKey = Map<String, Book>.of(_byKey)..[key] = updated;
    _favorites = _favorites.map((b) => b.key == key ? updated : b).toList(growable: false);
    notifyListeners();
    _scheduleSave();
  }

  Future<void> addTag(String key, String tag) async {
    final book = _byKey[key];
    if (book == null) return;
    final normalized = tag.trim().toLowerCase();
    if (normalized.isEmpty) return;
    final newTags = {...book.tags, normalized}.toList(growable: false);
    final updated = book.copyWith(tags: newTags);
    _byKey = Map<String, Book>.of(_byKey)..[key] = updated;
    _favorites = _favorites.map((b) => b.key == key ? updated : b).toList(growable: false);
    notifyListeners();
    _scheduleSave();
  }

  Future<void> removeTag(String key, String tag) async {
    final book = _byKey[key];
    if (book == null) return;
    final newTags = book.tags.where((t) => t != tag.trim().toLowerCase()).toList(growable: false);
    final updated = book.copyWith(tags: newTags);
    _byKey = Map<String, Book>.of(_byKey)..[key] = updated;
    _favorites = _favorites.map((b) => b.key == key ? updated : b).toList(growable: false);
    notifyListeners();
    _scheduleSave();
  }

  List<Book> searchFavorites(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return favorites;
    return _favorites
        .where((b) =>
            b.title.toLowerCase().contains(q) ||
            (b.authorName?.toLowerCase().contains(q) ?? false))
        .toList(growable: false);
  }

  String exportJson() {
    final data = {
      'version': 2,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'books': _favorites.map((b) => b.toJson()).toList(),
    };
    return jsonEncode(data);
  }

  Future<int> importJson(String source) async {
    try {
      final data = jsonDecode(source) as Map;
      final booksRaw = data['books'] as List;
      final imported = booksRaw
          .map((m) => Book.fromJson((m as Map).cast<String, dynamic>()))
          .toList(growable: false);

      int count = 0;
      for (final book in imported) {
        if (_byKey.containsKey(book.key)) {
          _byKey = Map<String, Book>.of(_byKey)..[book.key] = book;
        } else {
          _byKey = Map<String, Book>.of(_byKey)..[book.key] = book;
          count++;
        }
      }
      _favorites = _byKey.values.toList(growable: false);
      notifyListeners();
      _scheduleSave();
      return count;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> cancelPendingAction(String key) async {
    final idx = _pendingActions.lastIndexWhere((a) => a['key'] == key);
    if (idx == -1) return false;
    final updatedQueue = List<Map<String, dynamic>>.of(_pendingActions)..removeAt(idx);
    _pendingActions = updatedQueue;
    await _storage.savePendingActions(_pendingActions);
    return true;
  }

  void _scheduleSave() {
    _writeTimer?.cancel();
    _writeTimer = Timer(const Duration(milliseconds: 350), () {
      _storage.save(_favorites);
    });
  }

  Future<void> _processQueue() async {
    if (_processingQueue) return;
    _processingQueue = true;
    try {
      while (_pendingActions.isNotEmpty) {
        final action = _pendingActions.first;
        final success = await _sendActionToServer(action);
        if (success) {
          _pendingActions = List<Map<String, dynamic>>.of(_pendingActions)..removeAt(0);
          await _storage.savePendingActions(_pendingActions);
        } else {
          break;
        }
      }
    } finally {
      _processingQueue = false;
    }
  }

  Future<bool> _sendActionToServer(Map<String, dynamic> action) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return true;
  }
}
