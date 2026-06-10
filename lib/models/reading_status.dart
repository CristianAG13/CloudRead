enum ReadingStatus { toRead, reading, finished }

extension ReadingStatusX on ReadingStatus {
  String get name {
    switch (this) {
      case ReadingStatus.toRead:
        return 'toRead';
      case ReadingStatus.reading:
        return 'reading';
      case ReadingStatus.finished:
        return 'finished';
    }
  }

  static ReadingStatus fromName(String? name) {
    switch (name) {
      case 'reading':
        return ReadingStatus.reading;
      case 'finished':
        return ReadingStatus.finished;
      default:
        return ReadingStatus.toRead;
    }
  }
}
