import 'package:flutter/foundation.dart';

/// Holds the selected bottom-navigation tab so any screen can request a
/// tab switch (e.g. jump to Favorites after adding a book).
class NavController extends ChangeNotifier {
  static const int home = 0;
  static const int search = 1;
  static const int favorites = 2;

  int _index = home;
  int get index => _index;

  void goTo(int value) {
    if (_index == value) return;
    _index = value;
    notifyListeners();
  }

  void goToFavorites() => goTo(favorites);
}
