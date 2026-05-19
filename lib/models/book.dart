class Book {
  final String key;
  final String title;
  final String? authorName;
  final int? coverId;
  final int? firstPublishYear;
  final String? description;
  final List<String> subjects;
  final int? numberOfPages;

  Book({
    required this.key,
    required this.title,
    this.authorName,
    this.coverId,
    this.firstPublishYear,
    this.description,
    this.subjects = const [],
    this.numberOfPages,
  });

  factory Book.fromSearchJson(Map<String, dynamic> json) {
    return Book(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      authorName: (json['author_name'] as List?)?.firstOrNull as String?,
      coverId: json['cover_i'] as int?,
      firstPublishYear: json['first_publish_year'] as int?,
    );
  }

  factory Book.fromSubjectJson(Map<String, dynamic> json) {
    return Book(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      authorName: (json['authors'] as List?)
              ?.firstOrNull?['name'] as String? ??
          'Unknown Author',
      coverId: json['cover_id'] as int?,
      firstPublishYear: json['first_publish_year'] as int?,
    );
  }

  factory Book.fromDetailJson(Map<String, dynamic> json) {
    String? desc;
    final rawDesc = json['description'];
    if (rawDesc is String) {
      desc = rawDesc;
    } else if (rawDesc is Map && rawDesc['value'] is String) {
      desc = rawDesc['value'] as String;
    }

    return Book(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      authorName: (json['authors'] as List?)
              ?.firstOrNull?['author']?['key'] as String? ??
          'Unknown',
      coverId: (json['covers'] as List?)?.firstOrNull as int?,
      firstPublishYear: json['first_publish_date'] != null
          ? int.tryParse((json['first_publish_date'] as String).substring(0, 4))
          : null,
      description: desc,
      subjects: (json['subjects'] as List?)
              ?.cast<String>()
              .take(10)
              .toList() ??
          [],
      numberOfPages: json['number_of_pages'] as int?,
    );
  }

  /// For SQLite row
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      key: map['key'] as String? ?? '',
      title: map['title'] as String? ?? '',
      authorName: map['author_name'] as String?,
      coverId: map['cover_id'] as int?,
      firstPublishYear: map['first_publish_year'] as int?,
      description: map['description'] as String?,
      subjects: (map['subjects'] as String?)?.isNotEmpty == true
          ? (map['subjects'] as String).split('|')
          : [],
      numberOfPages: map['number_of_pages'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'title': title,
      'author_name': authorName,
      'cover_id': coverId,
      'first_publish_year': firstPublishYear,
      'description': description,
      'subjects': subjects.join('|'),
      'number_of_pages': numberOfPages,
    };
  }

  String get coverUrl {
    if (coverId != null) {
      return 'https://covers.openlibrary.org/b/id/$coverId-L.jpg';
    }
    return 'https://placehold.co/300x450/2C1810/FFF8F0?text=📚';
  }

  String get coverUrlMedium {
    if (coverId != null) {
      return 'https://covers.openlibrary.org/b/id/$coverId-M.jpg';
    }
    return 'https://placehold.co/200x300/2C1810/FFF8F0?text=📚';
  }

  Book copyWith({
    String? description,
    List<String>? subjects,
    int? numberOfPages,
  }) {
    return Book(
      key: key,
      title: title,
      authorName: authorName,
      coverId: coverId,
      firstPublishYear: firstPublishYear,
      description: description ?? this.description,
      subjects: subjects ?? this.subjects,
      numberOfPages: numberOfPages ?? this.numberOfPages,
    );
  }
}
