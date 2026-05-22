import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../services/database_service.dart';

class FavoritesProvider extends ChangeNotifier {
  List<Book> _favorites = [];
  bool _initialized = false;

  List<Book> get favorites => _favorites;
  bool get initialized => _initialized;

  /// Load all favorites from DB
  Future<void> loadFavorites() async {
    try {
      _favorites = await DatabaseService.getFavorites();
    } catch (_) {
      _favorites = [];
    }
    _initialized = true;
    notifyListeners();
  }

  /// Check if a book is favorited
  Future<bool> isFavorite(String key) async {
    return DatabaseService.isFavorite(key);
  }

  /// Toggle favorite status. Returns `true` if the book was added,
  /// `false` if it was removed. Updates in-memory state immediately and
  /// persists best-effort (web has no sqflite, so persistence is skipped).
  Future<bool> toggleFavorite(Book book) async {
    final exists = _favorites.any((b) => b.key == book.key);
    if (exists) {
      _favorites.removeWhere((b) => b.key == book.key);
      notifyListeners();
      try {
        await DatabaseService.removeFavorite(book.key);
      } catch (_) {}
      return false;
    } else {
      _favorites.insert(0, book);
      notifyListeners();
      try {
        await DatabaseService.addFavorite(book);
      } catch (_) {}
      return true;
    }
  }

  /// Remove from favorites
  Future<void> removeFavorite(String key) async {
    await DatabaseService.removeFavorite(key);
    _favorites.removeWhere((b) => b.key == key);
    notifyListeners();
  }

  /// Search within favorites (local)
  Future<List<Book>> searchFavorites(String query) async {
    if (query.trim().isEmpty) return _favorites;
    return DatabaseService.searchFavorites(query);
  }
}
