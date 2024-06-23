import 'package:flutter/material.dart';
import 'package:journal/user_store.dart';

class Tags extends StatefulWidget {
  final Map<String, Tag> tags;
  final Entry entry;
  const Tags(this.tags, this.entry);

  @override
  State<Tags> createState() => _TagsState();
}

class _TagsState extends State<Tags> {
  @override
  Widget build(BuildContext context) {
    return Row(
        children: widget.entry.tagIds.map((String tagId) {
      final tag = widget.tags[tagId]!;
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(20.0),
          ),
          color: Theme.of(context).colorScheme.primary.withOpacity(.75),
        ),
        margin: const EdgeInsets.only(right: 3.0, top: 3.0, bottom: 3.0),
        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 4.0),
        child: Row(
          children: [
            const SizedBox(width: 4.0),
            Text(
              '${tag.name}',
              style: TextStyle(fontSize: 12.0, color: Colors.white),
            ),
            const SizedBox(width: 4.0),
          ],
        ),
      );
    }).toList());
  }
}
