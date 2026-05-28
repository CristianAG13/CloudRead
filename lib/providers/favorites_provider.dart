import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../services/favorites_storage.dart';

/// Holds the user's favorite books in memory and keeps them in sync with a
/// persistent [FavoritesStorage] backend.
///
/// The provider exposes synchronous getters / search so the UI never has to
/// `await` to render. Persistence happens in the background as a best-effort
/// operation after each mutation, which keeps the UI snappy.
class FavoritesProvider extends ChangeNotifier {
  final FavoritesStorage _storage;

  List<Book> _favorites = const [];
  bool _initialized = false;

  /// Injects the storage backend (Dependency Inversion principle). Defaults
  /// to the SharedPreferences-backed implementation for production use.
  FavoritesProvider({FavoritesStorage? storage})
      : _storage = storage ?? SharedPreferencesFavoritesStorage();

  /// Read-only view of the favorites list (UI cannot mutate it directly).
  List<Book> get favorites => List.unmodifiable(_favorites);

  /// `true` once the initial load from storage has finished.
  bool get initialized => _initialized;

  /// Whether the given book is currently in the favorites list.
  bool isFavorite(String key) => _favorites.any((b) => b.key == key);

  /// Loads favorites from persistent storage into memory.
  Future<void> loadFavorites() async {
    _favorites = await _storage.load();
    _initialized = true;
    notifyListeners();
  }

  /// Toggles favorite status for [book]. Returns `true` if the book was
  /// added, `false` if it was removed. The in-memory state is updated and
  /// listeners are notified *before* persistence so the UI responds instantly.
  Future<bool> toggleFavorite(Book book) async {
    final wasFavorite = isFavorite(book.key);
    final updated = List<Book>.of(_favorites);
    if (wasFavorite) {
      updated.removeWhere((b) => b.key == book.key);
    } else {
      updated.insert(0, book);
    }
    _favorites = updated;
    notifyListeners();

    await _storage.save(_favorites);
    return !wasFavorite;
  }

  /// Removes a book from favorites by key. No-op if it is not present.
  Future<void> removeFavorite(String key) async {
    if (!isFavorite(key)) return;
    _favorites = _favorites.where((b) => b.key != key).toList(growable: false);
    notifyListeners();
    await _storage.save(_favorites);
  }

  /// Case-insensitive in-memory search by title or author. Returns the full
  /// list when [query] is empty or whitespace.
  List<Book> searchFavorites(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return favorites;
    return _favorites
        .where((b) =>
            b.title.toLowerCase().contains(q) ||
            (b.authorName?.toLowerCase().contains(q) ?? false))
        .toList(growable: false);
  }
}
