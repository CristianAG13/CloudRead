import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class ApiService {
  static const String _baseUrl = 'https://openlibrary.org';

  static const List<String> _trendingSubjects = [
    'fiction', 'fantasy', 'science_fiction', 'romance',
    'mystery', 'history', 'philosophy', 'science',
    'biography', 'poetry', 'adventure', 'horror',
  ];

  String _randomSubject() =>
      _trendingSubjects[Random().nextInt(_trendingSubjects.length)];

  /// Fetch books by subject (for discover feed)
  Future<List<Book>> fetchBooksBySubject({String? subject, int limit = 24}) async {
    final s = subject ?? _randomSubject();
    final uri = Uri.parse('$_baseUrl/subjects/$s.json?limit=$limit');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load books for subject: $s');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final works = (data['works'] as List?) ?? [];

    return works
        .map((w) => Book.fromSubjectJson(w as Map<String, dynamic>))
        .where((b) => b.key.isNotEmpty)
        .toList();
  }

  /// Search books by query
  Future<List<Book>> searchBooks(String query, {int limit = 24}) async {
    final uri = Uri.parse(
      '$_baseUrl/search.json?q=${Uri.encodeComponent(query)}&limit=$limit',
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Search failed');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final docs = (data['docs'] as List?) ?? [];

    return docs
        .map((d) => Book.fromSearchJson(d as Map<String, dynamic>))
        .where((b) => b.key.isNotEmpty)
        .toList();
  }

  /// Fetch full work details (description, subjects, etc.)
  Future<Book> fetchWorkDetails(String workKey) async {
    final uri = Uri.parse('$_baseUrl$workKey.json');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load book details');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Book.fromDetailJson(data);
  }

  /// Looks for a readable digital copy of the work on Internet Archive.
  ///
  /// Iterates the work's editions and returns the URL of the first one with
  /// an Internet Archive identifier (`ocaid`). Returns `null` when no edition
  /// has a digital scan available — which is the case for most copyrighted
  /// modern titles. Failures (network, parsing) are swallowed and reported
  /// as `null` so the UI can simply hide the "Read" button.
  Future<String?> fetchReadUrl(String workKey) async {
    try {
      final uri = Uri.parse('$_baseUrl$workKey/editions.json?limit=20');
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final entries = (data['entries'] as List?) ?? const [];
      for (final entry in entries) {
        if (entry is! Map<String, dynamic>) continue;
        final ocaid = entry['ocaid'] as String?;
        if (ocaid != null && ocaid.isNotEmpty) {
          return 'https://archive.org/details/$ocaid';
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  List<String> get trendingSubjects => _trendingSubjects;
}
