import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/reading_status.dart';
import 'tags_chip_input.dart';

class FavoriteCrudSheet extends StatefulWidget {
  final Book? bookToEdit;
  final Function(Book) onSave;
  final VoidCallback? onDelete;

  const FavoriteCrudSheet({
    super.key,
    this.bookToEdit,
    required this.onSave,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    Book? bookToEdit,
    required Function(Book) onSave,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FavoriteCrudSheet(
        bookToEdit: bookToEdit,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<FavoriteCrudSheet> createState() => _FavoriteCrudSheetState();
}

class _FavoriteCrudSheetState extends State<FavoriteCrudSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _authorCtrl;
  late TextEditingController _notesCtrl;

  double _rating = 0;
  ReadingStatus _status = ReadingStatus.toRead;
  List<String> _tags = const [];

  @override
  void initState() {
    super.initState();
    final b = widget.bookToEdit;
    _titleCtrl = TextEditingController(text: b?.title ?? '');
    _authorCtrl = TextEditingController(text: b?.authorName ?? '');
    _notesCtrl = TextEditingController(text: b?.personalNote ?? '');
    _rating = b?.personalRating ?? 0.0;
    _status = b?.readingStatus ?? ReadingStatus.toRead;
    _tags = List.of(b?.tags ?? const []);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final isNew = widget.bookToEdit == null;
      final key = isNew
          ? 'manual_${DateTime.now().millisecondsSinceEpoch}'
          : widget.bookToEdit!.key;

      final updatedBook = Book(
        key: key,
        title: _titleCtrl.text.trim(),
        authorName: _authorCtrl.text.trim(),
        personalNote: _notesCtrl.text.trim(),
        personalRating: _rating,
        readingStatus: _status,
        tags: _tags,
        coverId: widget.bookToEdit?.coverId,
        firstPublishYear: widget.bookToEdit?.firstPublishYear,
        description: widget.bookToEdit?.description,
        subjects: widget.bookToEdit?.subjects ?? const [],
        numberOfPages: widget.bookToEdit?.numberOfPages,
        readUrl: widget.bookToEdit?.readUrl,
        addedAt: widget.bookToEdit?.addedAt,
      );

      widget.onSave(updatedBook);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.bookToEdit == null ? 'Add Custom Book' : 'Edit Favorite',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleCtrl,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'Book Title',
                  filled: true,
                  fillColor: colors.surfaceContainer,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (val) => val != null && val.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _authorCtrl,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'Author Name',
                  filled: true,
                  fillColor: colors.surfaceContainer,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Reading Status',
                style: theme.textTheme.titleSmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              _StatusSelector(value: _status, onChanged: (s) => setState(() => _status = s)),
              const SizedBox(height: 24),
              Text(
                'Tags',
                style: theme.textTheme.titleSmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              TagsChipInput(
                tags: _tags,
                onChanged: (t) => setState(() => _tags = t),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'Personal Notes (Optional)',
                  filled: true,
                  fillColor: colors.surfaceContainer,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Your Rating',
                style: theme.textTheme.titleSmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: colors.primary,
                  inactiveTrackColor: colors.surfaceContainer,
                  thumbColor: colors.primary,
                  valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                ),
                child: Slider(
                  value: _rating,
                  min: 0.0,
                  max: 5.0,
                  divisions: 10,
                  label: _rating.toStringAsFixed(1),
                  onChanged: (val) {
                    setState(() => _rating = val);
                  },
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  if (widget.bookToEdit != null && widget.onDelete != null) ...[
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onDelete!();
                      },
                      icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                      tooltip: 'Remove from Favorites',
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final ReadingStatus value;
  final ValueChanged<ReadingStatus> onChanged;

  const _StatusSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      children: ReadingStatus.values.map((s) {
        final isSelected = s == value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: s == ReadingStatus.toRead ? 0 : 6,
              right: s == ReadingStatus.finished ? 0 : 6,
            ),
            child: Material(
              color: isSelected ? colors.primary : colors.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onChanged(s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _label(s),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _label(ReadingStatus s) {
    switch (s) {
      case ReadingStatus.toRead:
        return 'To read';
      case ReadingStatus.reading:
        return 'Reading';
      case ReadingStatus.finished:
        return 'Finished';
    }
  }
}
