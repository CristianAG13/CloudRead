import 'package:flutter/material.dart';

class TagsChipInput extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  const TagsChipInput({
    super.key,
    required this.tags,
    required this.onChanged,
  });

  @override
  State<TagsChipInput> createState() => _TagsChipInputState();
}

class _TagsChipInputState extends State<TagsChipInput> {
  final _controller = TextEditingController();
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _tags = List.of(widget.tags);
  }

  @override
  void didUpdateWidget(TagsChipInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tags != widget.tags) {
      _tags = List.of(widget.tags);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTag(String raw) {
    final tag = raw.trim().toLowerCase();
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() {
      _tags = [..._tags, tag];
    });
    widget.onChanged(_tags);
    _controller.clear();
  }

  void _removeTag(String tag) {
    setState(() {
      _tags = _tags.where((t) => t != tag).toList(growable: false);
    });
    widget.onChanged(_tags);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in _tags)
                Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 13)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeTag(tag),
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  side: BorderSide(color: Theme.of(context).colorScheme.outline),
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: _tags.isEmpty ? 'No tags yet. Type to add...' : 'Add a tag...',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              onPressed: () => _addTag(_controller.text),
            ),
          ),
          onSubmitted: _addTag,
        ),
      ],
    );
  }
}
