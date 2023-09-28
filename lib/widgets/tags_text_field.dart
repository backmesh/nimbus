import 'dart:math';

import 'package:flutter/material.dart';

class TagsTextField extends StatefulWidget {
  @override
  _TagsTextFieldState createState() => _TagsTextFieldState();
}

class _TagsTextFieldState extends State<TagsTextField> {
  final List<String> _tags = [];
  final TextEditingController _controller = TextEditingController();
  final List<String> _suggestions = [
    'Apple',
    'Banana',
    'Cherry',
    'Date',
    'Grape',
    'Mango',
    'Orange',
  ];

  List<String> _filteredSuggestions = [];

  void _filterSuggestions() {
    final query = _controller.text.toLowerCase();
    _filteredSuggestions = _suggestions
        .where((suggestion) => suggestion.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
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
            final text = _filteredSuggestions.length == 0
                ? _controller.text
                : _filteredSuggestions[index];
            return ListTile(
              title: Text(text),
              onTap: () {
                setState(() {
                  _tags.add(text);
                  _controller.clear();
                  _filteredSuggestions.clear();
                });
              },
            );
          },
        ),
      ),
      Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: _tags
            .map((tag) => Chip(
                  label: Text(tag),
                  onDeleted: () {
                    setState(() {
                      _tags.remove(tag);
                    });
                  },
                ))
            .toList(),
      ),
    ]);
  }
}
