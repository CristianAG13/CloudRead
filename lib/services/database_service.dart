import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/book.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'lectura.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favorites (
            key TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            author_name TEXT,
            cover_id INTEGER,
            first_publish_year INTEGER,
            description TEXT,
            subjects TEXT,
            number_of_pages INTEGER
          )
        ''');
      },
    );
  }

  // --- Favorites CRUD ---

  static Future<List<Book>> getFavorites() async {
    final db = await database;
    final rows = await db.query('favorites', orderBy: 'rowid DESC');
    return rows.map((row) => Book.fromMap(row)).toList();
  }

  static Future<bool> isFavorite(String key) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'key = ?',
      whereArgs: [key],
    );
    return result.isNotEmpty;
  }

  static Future<void> addFavorite(Book book) async {
    final db = await database;
    await db.insert(
      'favorites',
      book.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<void> removeFavorite(String key) async {
    final db = await database;
    await db.delete('favorites', where: 'key = ?', whereArgs: [key]);
  }

  /// Search within favorites
  static Future<List<Book>> searchFavorites(String query) async {
    final db = await database;
    final pattern = '%$query%';
    final rows = await db.query(
      'favorites',
      where: 'title LIKE ? OR author_name LIKE ?',
      whereArgs: [pattern, pattern],
      orderBy: 'rowid DESC',
    );
    return rows.map((row) => Book.fromMap(row)).toList();
  }
}
