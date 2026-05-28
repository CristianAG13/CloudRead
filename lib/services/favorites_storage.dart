import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';

/// Contract for persisting the user's favorite books across app restarts.
///
/// Defined as an abstract interface so the [FavoritesProvider] depends on the
/// abstraction (not a concrete backend). This lets us swap implementations
/// (e.g. an in-memory fake for tests, or a different backend like Hive)
/// without touching the provider or the UI.
abstract class FavoritesStorage {
  /// Reads the persisted favorites. Returns an empty list when nothing has
  /// been stored yet or when the stored data cannot be decoded.
  Future<List<Book>> load();

  /// Persists the full favorites list atomically. The list is treated as the
  /// source of truth and overwrites whatever was previously stored.
  Future<void> save(List<Book> favorites);
}

/// [FavoritesStorage] backed by `shared_preferences`.
///
/// Works on every Flutter platform (Android, iOS, Web, Windows, macOS, Linux)
/// because the underlying plugin has implementations for all of them. The
/// favorites list is JSON-encoded into a single key, which is more than
/// enough capacity for the typical "tens of favorites" use case.
class SharedPreferencesFavoritesStorage implements FavoritesStorage {
  /// Versioned key — bump the suffix (`v2`, …) if the persisted schema
  /// changes so that we can migrate or invalidate old data cleanly.
  static const String _storageKey = 'cloudread.favorites.v1';

  @override
  Future<List<Book>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map>()
          .map((m) => Book.fromJson(m.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (_) {
      // Corrupt or unreadable data should never crash the app — degrade to
      // an empty library and let the user keep using CloudRead.
      return const [];
    }
  }

  @override
  Future<void> save(List<Book> favorites) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(favorites.map((b) => b.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {
      // Best-effort: a failed write must not break the already-updated UI.
    }
  }
}
