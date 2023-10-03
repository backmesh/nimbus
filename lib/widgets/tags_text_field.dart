import 'dart:math';

import 'package:flutter/material.dart';
import 'package:journal/user_store.dart';

class TagsTextField extends StatefulWidget {
  final Map<String, Tag> tags;
  final Entry entry;
  const TagsTextField(this.tags, this.entry);

  @override
  _TagsTextFieldState createState() => _TagsTextFieldState();
}

class _TagsTextFieldState extends State<TagsTextField> {
  final TextEditingController _controller = TextEditingController();
  Map<String, Tag> _filteredSuggestions = {};

  void _filterSuggestions() {
    final query = _controller.text.toLowerCase();
    _filteredSuggestions = {
      for (var entry in widget.tags.entries)
        if (entry.value.name.toLowerCase().contains(query))
          entry.key: entry.value
    };
  }

  void _tagEntry(String tagId, Tag tag) {
    setState(() {
      if (!widget.entry.tagIds.contains(tagId)) {
        widget.entry.tagIds.add(tagId);
        UserStore.instance.updateEntry(widget.entry);
      }
      _controller.clear();
      _filteredSuggestions.clear();
    });
  }

  void _untagEntry(String tagId, Tag tag) {
    if (widget.entry.tagIds.remove(tagId))
      UserStore.instance.updateEntry(widget.entry);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> _entryTagIds = widget.entry.tagIds; // entry tags

    _filterSuggestions();

    // Build the widget based on the document data
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: _controller,
          onChanged: (value) {
            setState(() {
              _filterSuggestions();
            });
          },
          decoration: InputDecoration(
            hintText: '+ Tag',
          ),
        ),
      ),
      Container(
        height: 100,
        child: ListView.builder(
          itemCount: max(_filteredSuggestions.length, 1),
          itemBuilder: (context, index) {
            // new tag
            if (_filteredSuggestions.length == 0) {
              final text = _controller.text;
              if (text.isEmpty) return null;
              return ListTile(
                title: Text(text),
                onTap: () async {
                  final tag = Tag(name: text, color: Tag.getRandomColor());
                  final doc = await UserStore.instance.newTag(tag);
                  _tagEntry(doc.id, tag);
                },
              );
            } else {
              final entry = _filteredSuggestions.entries.elementAt(index);
              return ListTile(
                title: Text(entry.value.name),
                onTap: () => _tagEntry(entry.key, entry.value),
              );
            }
          },
        ),
      ),
      Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _entryTagIds.map((tagId) {
            final tag = widget.tags[tagId]!;
            return Chip(
                label: Text(tag.name),
                onDeleted: () => _untagEntry(tagId, tag));
          }).toList())
    ]);
  }
}
