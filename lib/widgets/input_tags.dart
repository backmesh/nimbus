import 'package:flutter/material.dart';
import 'package:journal/user_store.dart';

class InputTags extends StatefulWidget {
  final Map<String, Tag> tags;
  final Entry entry;
  const InputTags(this.tags, this.entry);

  @override
  State<InputTags> createState() => _InputTagsState();
}

class _InputTagsState extends State<InputTags> {
  double? _distanceToField;
  Map<String, Tag> _filteredSuggestions = {};

  void _filterSuggestions(String query) {
    _filteredSuggestions = {
      for (var entry in widget.tags.entries)
        if (entry.value.name.toLowerCase().contains(query))
          entry.key: entry.value
    };
  }

  void _tagEntry(String tagId) {
    setState(() {
      if (!widget.entry.tagIds.contains(tagId)) {
        widget.entry.tagIds.add(tagId);
        UserStore.instance.updateEntry(widget.entry);
      }
      _filteredSuggestions.clear();
    });
  }

  void _untagEntry(String tagId) {
    if (widget.entry.tagIds.remove(tagId))
      UserStore.instance.updateEntry(widget.entry);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      _distanceToField = MediaQuery.of(context).size.width;
    });
  }

  @override
  Widget build(BuildContext context) {
    // List<String> _userTags = widget.tags.values.map((e) => e.name).toList();
    // List<String> _entryTags =
    //     widget.entry.tagIds.map((e) => widget.tags[e]!.name).toList();
    return Column(children: [
      Autocomplete<MapEntry<String, Tag>>(
          optionsViewBuilder: (context, onSelected, options) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              elevation: 4.0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final MapEntry<String, Tag> option =
                        options.elementAt(index);
                    return TextButton(
                      onPressed: () {
                        onSelected(option);
                      },
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                          child: Text(
                            '${option.value.name}',
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 74, 137, 92),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      }, optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable.empty();
        }
        final value = textEditingValue.text.toLowerCase();
        _filterSuggestions(value);
        return _filteredSuggestions.entries;
        // return widget.tags.values.where((Tag option) {
        //   return option.name.contains(value);
        // });
      }, onSelected: (MapEntry<String, Tag> selectedEntry) async {
        print(selectedEntry);
        //final doc = await UserStore.instance.newTag(selectedEntry.value);
        _tagEntry(selectedEntry.key);
      }, fieldViewBuilder: (context, ttec, tfn, onFieldSubmitted) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: TextField(
            controller: ttec,
            focusNode: tfn,
            decoration: InputDecoration(
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent, width: 3.0),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                    color: Color.fromARGB(255, 74, 137, 92), width: 3.0),
              ),
              hintText: widget.entry.tagIds.isNotEmpty ? '' : 'Tag +',
              //errorText: error,
              prefixIconConstraints:
                  BoxConstraints(maxWidth: _distanceToField! * 0.74),
              prefixIcon: widget.entry.tagIds.isNotEmpty
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                          children: widget.entry.tagIds.map((String tagId) {
                        final tag = widget.tags[tagId]!;
                        return Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(
                              Radius.circular(20.0),
                            ),
                            color: Color.fromARGB(255, 74, 137, 92),
                          ),
                          margin: const EdgeInsets.only(right: 10.0),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                child: Text(
                                  '${tag.name}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                onTap: () {
                                  //print("$tag selected");
                                },
                              ),
                              const SizedBox(width: 4.0),
                              InkWell(
                                child: const Icon(
                                  Icons.cancel,
                                  size: 14.0,
                                  color: Color.fromARGB(255, 233, 233, 233),
                                ),
                                onTap: () {
                                  _untagEntry(tagId);
                                },
                              )
                            ],
                          ),
                        );
                      }).toList()),
                    )
                  : null,
            ),
            // onChanged: (String newValue) {
            //   _filterSuggestions(newValue);
            //   //print(newValue);
            // },
            // onSubmitted: onSubmitted,
          ),
        );
      })
    ]);
  }
}
// class TagsTextField extends StatefulWidget {
//   final Map<String, Tag> tags;
//   final Entry entry;
//   const TagsTextField(this.tags, this.entry);

//   @override
//   _TagsTextFieldState createState() => _TagsTextFieldState();
// }

// class _TagsTextFieldState extends State<TagsTextField> {
//   final TextEditingController _controller = TextEditingController();
//   final FocusNode _focusNode = FocusNode();
//   Map<String, Tag> _filteredSuggestions = {};
//   bool _showTagEditor = true;

//   void _handleFocusChange() {
//     print(_focusNode.hasFocus);
//     setState(() {
//       _showTagEditor = _focusNode.hasFocus;
//     });
//   }

//   @override
//   void initState() {
//     super.initState();
//     _focusNode.addListener(_handleFocusChange);
//   }

//   @override
//   void dispose() {
//     _focusNode.removeListener(_handleFocusChange);
//     _focusNode.dispose();
//     super.dispose();
//   }

//   void _filterSuggestions() {
//     final query = _controller.text.toLowerCase();
//     _filteredSuggestions = {
//       for (var entry in widget.tags.entries)
//         if (entry.value.name.toLowerCase().contains(query))
//           entry.key: entry.value
//     };
//   }

//   void _tagEntry(String tagId, Tag tag) {
//     setState(() {
//       if (!widget.entry.tagIds.contains(tagId)) {
//         widget.entry.tagIds.add(tagId);
//         UserStore.instance.updateEntry(widget.entry);
//       }
//       _controller.clear();
//       _filteredSuggestions.clear();
//     });
//   }

//   void _untagEntry(String tagId, Tag tag) {
//     if (widget.entry.tagIds.remove(tagId))
//       UserStore.instance.updateEntry(widget.entry);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final List<String> _entryTagIds = widget.entry.tagIds; // entry tags

//     if (_showTagEditor) {
//       final List<Widget> chips = _entryTagIds.map((tagId) {
//         final tag = widget.tags[tagId]!;
//         return InputChip(
//             label: Text(tag.name), onDeleted: () => _untagEntry(tagId, tag));
//       }).toList();
//       chips.add(InputChip(
//         label: Container(
//           width: 100, // You can adjust the width as needed
//           child: TextField(
//             decoration: InputDecoration(hintText: '+ Tag'),
//           ),
//         ),
//       ));
//       return Wrap(spacing: 4.0, runSpacing: 4.0, children: chips);
//     }

//     _filterSuggestions();

//     // Build the widget based on the document data
//     return Column(children: [
//       Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: TextField(
//           controller: _controller,
//           //focusNode: _focusNode,
//           onChanged: (value) {
//             setState(() {
//               _filterSuggestions();
//             });
//           },
//           onSubmitted: (e) => setState(() {
//             _showTagEditor = false;
//           }),
//           decoration: InputDecoration(
//             hintText: '+ Tag',
//           ),
//         ),
//       ),
//       Container(
//         height: 100,
//         child: ListView.builder(
//           itemCount: max(_filteredSuggestions.length, 1),
//           itemBuilder: (context, index) {
//             // new tag
//             if (_filteredSuggestions.length == 0) {
//               final text = _controller.text;
//               if (text.isEmpty) return null;
//               return ListTile(
//                 title: Text(text),
//                 onTap: () async {
//                   final tag = Tag(name: text, color: Tag.getRandomColor());
//                   final doc = await UserStore.instance.newTag(tag);
//                   _tagEntry(doc.id, tag);
//                 },
//               );
//             } else {
//               final entry = _filteredSuggestions.entries.elementAt(index);
//               return ListTile(
//                 title: Text(entry.value.name),
//                 onTap: () => _tagEntry(entry.key, entry.value),
//               );
//             }
//           },
//         ),
//       ),
//       Wrap(
//           spacing: 4.0,
//           runSpacing: 4.0,
//           children: _entryTagIds.map((tagId) {
//             final tag = widget.tags[tagId]!;
//             return Chip(
//                 label: Text(tag.name),
//                 onDeleted: () => _untagEntry(tagId, tag));
//           }).toList())
//     ]);
//   }
// }
