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
  Future<void> _tagEntry(String tagId) async {
    if (!widget.entry.tagIds.contains(tagId)) {
      widget.entry.tagIds.add(tagId);
      await UserStore.instance.updateEntry(widget.entry);
    }
  }

  Future<void> _untagEntry(String tagId) async {
    if (widget.entry.tagIds.remove(tagId))
      UserStore.instance.updateEntry(widget.entry);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Autocomplete<MapEntry<String, Tag>>(
          displayStringForOption: (MapEntry<String, Tag> option) =>
              option.value.name,
          optionsViewBuilder: (context, onSelected, options) {
            return Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: Material(
                  elevation: 4.0,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final MapEntry<String, Tag> option =
                            options.elementAt(index);
                        return TextButton(
                          onPressed: () async {
                            onSelected(option);
                          },
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15.0),
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
          },
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text == '') {
              final _filteredSuggestions = {
                for (var entry in widget.tags.entries)
                  if (!widget.entry.tagIds.contains(entry.key))
                    entry.key: entry.value
              };
              return _filteredSuggestions.entries;
            }
            ;
            final query = textEditingValue.text.toLowerCase();
            final _filteredSuggestions = {
              for (var entry in widget.tags.entries)
                if (!widget.entry.tagIds.contains(entry.key) &&
                    entry.value.name.toLowerCase().contains(query))
                  entry.key: entry.value
            };
            return _filteredSuggestions.entries.followedBy([
              MapEntry('create', Tag(color: Tag.getRandomColor(), name: query))
            ]);
          },
          onSelected: (MapEntry<String, Tag> selectedEntry) async {
            if (selectedEntry.key == 'create') {
              final doc = await UserStore.instance.newTag(selectedEntry.value);
              return await _tagEntry(doc.id);
            }
            await _tagEntry(selectedEntry.key);
          },
          fieldViewBuilder: (context, ttec, tfn, onFieldSubmitted) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        // Handle tap here if needed
                      },
                      child: Container(
                        width: 200, // You can adjust this width as needed
                        child: TextField(
                          controller: ttec,
                          focusNode: tfn,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0),
                              borderSide: tfn.hasFocus
                                  ? BorderSide(
                                      color: Color.fromARGB(255, 74, 137, 92),
                                      width: 3.0)
                                  : BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            hintText:
                                widget.entry.tagIds.isNotEmpty ? '' : '+Tag',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 10.0),
                          ),
                        ),
                      ),
                    ),
                    ...widget.entry.tagIds.map((String tagId) {
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
                              onTap: () {},
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
                    }).toList(),
                  ],
                ),
              ),
            );
          })
    ]);
  }
}
