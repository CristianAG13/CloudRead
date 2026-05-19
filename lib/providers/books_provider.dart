import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../services/api_service.dart';

enum LoadingState { idle, loading, loaded, error }

class BooksProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  LoadingState _state = LoadingState.idle;
  String _errorMessage = '';
  List<Book> _books = [];
  String _currentSubject = '';

  // Search
  LoadingState _searchState = LoadingState.idle;
  List<Book> _searchResults = [];
  String _currentQuery = '';

  // Getters
  LoadingState get state => _state;
  String get errorMessage => _errorMessage;
  List<Book> get books => _books;
  String get currentSubject => _currentSubject;

  LoadingState get searchState => _searchState;
  List<Book> get searchResults => _searchResults;
  String get currentQuery => _currentQuery;

  /// Load discover books by random subject
  Future<void> loadDiscoverBooks({String? subject}) async {
    _state = LoadingState.loading;
    notifyListeners();

    try {
      final result = await _api.fetchBooksBySubject(subject: subject);
      _books = result;
      _currentSubject = subject ?? _currentSubject;
      _state = LoadingState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = LoadingState.error;
    }

    notifyListeners();
  }

  /// Search books
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

  /// Fetch full detail for a book (description, subjects)
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

  void clearSearch() {
    _searchResults = [];
    _searchState = LoadingState.idle;
    _currentQuery = '';
    notifyListeners();
  }
}
