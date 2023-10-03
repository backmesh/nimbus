import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:journal/user_store.dart';

class TagsTextField extends StatefulWidget {
  final Journalist user;
  final Entry entry;
  const TagsTextField(this.user, this.entry);

  @override
  _TagsTextFieldState createState() => _TagsTextFieldState();
}

class _TagsTextFieldState extends State<TagsTextField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _filteredSuggestions = [];

  void _filterSuggestions() {
    final query = _controller.text.toLowerCase();
    final List<String> suggestions = widget.user.tags;
    print('_filterSuggestions');
    print(suggestions);
    _filteredSuggestions = suggestions
        .where((tag) =>
            !widget.entry.tags.contains(tag) &&
            tag.toLowerCase().contains(query))
        .toList();
  }

  void _addTag(String text) {
    if (text.isEmpty) return;
    setState(() {
      //_entryTags.add(text);
      if (!widget.entry.tags.contains(text)) {
        widget.entry.tags.add(text);
        //print(widget.entry.tags);
        UserStore.instance.updateEntry(widget.entry);
      }
      if (!widget.user.tags.contains(text)) {
        widget.user.tags.add(text);
        //print(user!.tags);
        UserStore.instance.updateUser(widget.user);
      }
      _controller.clear();
      _filteredSuggestions.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() {
      //_entryTags.remove(tag);
      if (widget.entry.tags.remove(tag))
        UserStore.instance.updateEntry(widget.entry);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> _entryTags = widget.entry.tags; // entry tags

    _filterSuggestions();

    // Build the widget based on the document data
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: RawKeyboardListener(
          focusNode: _focusNode,
          onKey: (RawKeyEvent event) {
            if (event is RawKeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.enter) {
              _addTag(_controller.text.toLowerCase());
            }
          },
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
      ),
      Container(
        height: 100,
        child: ListView.builder(
          itemCount: _filteredSuggestions.length,
          itemBuilder: (context, index) {
            final text = _filteredSuggestions.length == 0
                ? _controller.text
                : _filteredSuggestions[index];
            return ListTile(
              title: Text(text),
              onTap: () => _addTag(text),
            );
          },
        ),
      ),
      Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: _entryTags
            .map((tag) => Chip(
                  label: Text(tag),
                  onDeleted: () => _removeTag(tag),
                ))
            .toList(),
      ),
    ]);
  }
}
