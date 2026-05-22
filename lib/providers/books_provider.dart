import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../services/api_service.dart';

enum LoadingState { idle, loading, loaded, error }

/// A horizontal row of books grouped by category (Netflix-style shelf).
class Shelf {
  final String subject;
  final String label;
  final List<Book> books;

  const Shelf({
    required this.subject,
    required this.label,
    required this.books,
  });
}

/// Display labels for the Open Library subjects we surface as categories.
const Map<String, String> kCategories = {
  'fiction': 'Fiction',
  'fantasy': 'Fantasy',
  'science_fiction': 'Science Fiction',
  'mystery': 'Mystery & Thriller',
  'romance': 'Romance',
  'history': 'History',
  'biography': 'Biography',
  'philosophy': 'Philosophy',
  'poetry': 'Poetry',
  'horror': 'Horror',
  'adventure': 'Adventure',
  'science': 'Science',
};

class BooksProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  // --- Home (streaming-style shelves) ---
  LoadingState _homeState = LoadingState.idle;
  List<Shelf> _shelves = [];
  Book? _featured;
  String _errorMessage = '';

  LoadingState get homeState => _homeState;
  List<Shelf> get shelves => _shelves;
  Book? get featured => _featured;
  String get errorMessage => _errorMessage;
  Map<String, String> get categories => kCategories;

  // --- Search ---
  LoadingState _searchState = LoadingState.idle;
  List<Book> _searchResults = [];
  String _currentQuery = '';

  LoadingState get searchState => _searchState;
  List<Book> get searchResults => _searchResults;
  String get currentQuery => _currentQuery;

  // --- Category browse ---
  LoadingState _browseState = LoadingState.idle;
  List<Book> _browseResults = [];
  String _browseLabel = '';

  LoadingState get browseState => _browseState;
  List<Book> get browseResults => _browseResults;
  String get browseLabel => _browseLabel;

  /// Load the home feed: a featured book plus several category shelves,
  /// each fetched in parallel for speed.
  Future<void> loadHome() async {
    _homeState = LoadingState.loading;
    notifyListeners();

    final subjects = kCategories.keys.toList()..shuffle(Random());
    final picked = subjects.take(6).toList();

    try {
      final results = await Future.wait(
        picked.map((s) => _api.fetchBooksBySubject(subject: s, limit: 18)),
      );

      final shelves = <Shelf>[];
      for (var i = 0; i < picked.length; i++) {
        final books = results[i];
        if (books.isNotEmpty) {
          shelves.add(
            Shelf(
              subject: picked[i],
              label: kCategories[picked[i]] ?? picked[i],
              books: books,
            ),
          );
        }
      }

      if (shelves.isEmpty) {
        _errorMessage = 'No books available right now.';
        _homeState = LoadingState.error;
      } else {
        _shelves = shelves;
        _featured = _pickFeatured(shelves);
        _homeState = LoadingState.loaded;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _homeState = LoadingState.error;
    }

    notifyListeners();
  }

  Book? _pickFeatured(List<Shelf> shelves) {
    final candidates = shelves
        .expand((s) => s.books)
        .where((b) => b.coverId != null)
        .toList();
    if (candidates.isEmpty) return shelves.first.books.first;
    return candidates[Random().nextInt(candidates.length)];
  }

  /// Search books by free-text query.
  Future<void> searchBooks(String query) async {
    _currentQuery = query;
    if (query.trim().isEmpty) {
      _searchResults = [];
      _searchState = LoadingState.idle;
      notifyListeners();
      return;
    }

    _searchState = LoadingState.loading;
    notifyListeners();

    try {
      _searchResults = await _api.searchBooks(query);
      _searchState = LoadingState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _searchState = LoadingState.error;
    }

    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _searchState = LoadingState.idle;
    _currentQuery = '';
    notifyListeners();
  }

  /// Load a full grid of books for a single category.
  Future<void> loadCategory(String subject, String label) async {
    _browseLabel = label;
    _browseResults = [];
    _browseState = LoadingState.loading;
    notifyListeners();

    try {
      _browseResults = await _api.fetchBooksBySubject(
        subject: subject,
        limit: 48,
      );
      _browseState = LoadingState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _browseState = LoadingState.error;
    }

    notifyListeners();
  }

  /// Fetch full detail for a book (description, subjects, page count).
  Future<Book> fetchDetail(Book baseBook) async {
    try {
      final detail = await _api.fetchWorkDetails(baseBook.key);
      return baseBook.copyWith(
        description: detail.description,
        subjects: detail.subjects,
        numberOfPages: detail.numberOfPages,
      );
    } catch (_) {
      return baseBook;
    }
  }
}
