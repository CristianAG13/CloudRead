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
    _favorites = await DatabaseService.getFavorites();
    _initialized = true;
    notifyListeners();
  }

  /// Check if a book is favorited
  Future<bool> isFavorite(String key) async {
    return DatabaseService.isFavorite(key);
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(Book book) async {
    final exists = _favorites.any((b) => b.key == book.key);
    if (exists) {
      await DatabaseService.removeFavorite(book.key);
      _favorites.removeWhere((b) => b.key == book.key);
    } else {
      await DatabaseService.addFavorite(book);
      _favorites.insert(0, book);
    }
    notifyListeners();
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
