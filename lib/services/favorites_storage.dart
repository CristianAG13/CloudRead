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

  /// Loads the queue of pending actions (add/remove) that need to be sent to
  /// the remote API. Returns an empty list when none exist.
  Future<List<Map<String, dynamic>>> loadPendingActions();

  /// Persists the pending actions queue.
  Future<void> savePendingActions(List<Map<String, dynamic>> actions);
}

/// [FavoritesStorage] backed by `shared_preferences`.
///
/// Works on every Flutter platform (Android, iOS, Web, Windows, macOS, Linux)
/// because the underlying plugin has implementations for all of them. The
/// favorites list is JSON-encoded into a single key, which is more than
/// enough capacity for the typical "tens of favorites" use case.
class SharedPreferencesFavoritesStorage implements FavoritesStorage {
  static const String _keyV2 = 'cloudread.favorites.v2';
  static const String _keyV1 = 'cloudread.favorites.v1';
  static const String _queueKey = 'cloudread.favorites.queue.v1';

  @override
  Future<List<Book>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawV2 = prefs.getString(_keyV2);
      if (rawV2 != null && rawV2.isNotEmpty) {
        return _decodeList(rawV2);
      }

      final rawV1 = prefs.getString(_keyV1);
      if (rawV1 == null || rawV1.isEmpty) return const [];

      final migrated = _migrateFromV1(rawV1);
      if (migrated.isNotEmpty) {
        await save(migrated);
        await prefs.remove(_keyV1);
      }
      return migrated;
    } catch (_) {
      return const [];
    }
  }

  List<Book> _migrateFromV1(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.whereType<Map>().map((m) {
        final map = m.cast<String, dynamic>();
        return Book.fromJson({
          ...map,
          if (!map.containsKey('reading_status')) 'reading_status': 'toRead',
          if (!map.containsKey('tags')) 'tags': <String>[],
          if (!map.containsKey('added_at'))
            'added_at': DateTime.now().toUtc().toIso8601String(),
        });
      }).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  List<Book> _decodeList(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((m) => Book.fromJson(m.cast<String, dynamic>()))
        .toList(growable: false);
  }

  @override
  Future<void> save(List<Book> favorites) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(favorites.map((b) => b.toJson()).toList());
      await prefs.setString(_keyV2, encoded);
    } catch (_) {
      // Best-effort: a failed write must not break the already-updated UI.
    }
  }

  @override
  Future<List<Map<String, dynamic>>> loadPendingActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_queueKey);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> savePendingActions(List<Map<String, dynamic>> actions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(actions);
      await prefs.setString(_queueKey, encoded);
    } catch (_) {
      // Best-effort: ignore write failures
    }
  }
}

/// In-memory implementation for tests. Does not persist.
class InMemoryFavoritesStorage implements FavoritesStorage {
  List<Book> _data = const [];
  List<Map<String, dynamic>> _pending = const [];

  @override
  Future<List<Book>> load() async => List.unmodifiable(_data);

  @override
  Future<void> save(List<Book> favorites) async {
    _data = List.of(favorites);
  }

  @override
  Future<List<Map<String, dynamic>>> loadPendingActions() async =>
      List.unmodifiable(_pending);

  @override
  Future<void> savePendingActions(List<Map<String, dynamic>> actions) async {
    _pending = List.of(actions);
  }
}
