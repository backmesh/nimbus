import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;

import '../user_store.dart';
import 'entry.dart';

class JournalPage extends StatefulWidget {
  final Map<String, Tag> tags;
  const JournalPage(this.tags);

  @override
  _JournalPageState createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  late ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height * .9;
    return Container(
      padding: EdgeInsets.all(20),
      child: FirestoreQueryBuilder<Entry>(
          query: UserStore.instance.readEntries(),
          builder: (context, snapshot, _) {
            // Loading
            if (snapshot.hasMore ||
                snapshot.isFetching ||
                snapshot.isFetchingMore) {
              snapshot.fetchMore();
              return Center(child: CircularProgressIndicator());
            }
            final today = getToday();
            final lastEntry = snapshot.docs.firstOrNull?.data();
            final noTodayEntry =
                lastEntry == null || !isSameCalendarDay(today, lastEntry.date);
            if (noTodayEntry) {
              // create today and fetch more
              UserStore.instance
                  .updateEntry(Entry(doc: Document(), date: today, tagIds: []))
                  .then((_) => snapshot.fetchMore());
              return Center(child: CircularProgressIndicator());
            }

            final itemCount = snapshot.docs.length;
            double minEntryHeight = screenHeight / min(itemCount, 4);
            return ListView.builder(
              reverse: true,
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              controller: _controller,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: itemCount,
              findChildIndexCallback: (Key key) {
                final valueKey = key as ValueKey<String>;
                return snapshot.docs
                    .indexWhere((doc) => doc.id == valueKey.value);
              },
              itemBuilder: (context, index) {
                // index 0 is today
                final QueryDocumentSnapshot<Entry> doc = snapshot.docs[index];
                final Entry entry = doc.data();
                final Entry? prevEntry =
                    snapshot.docs.elementAtOrNull(index + 1)?.data();
                final prevEntryDate =
                    prevEntry != null ? prevEntry.date : DateTime(2010);
                return ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minEntryHeight),
                    child: KeyedSubtree(
                      key: ValueKey(doc.id), // Unique key for each item
                      child: EntryPage(_controller, widget.tags, entry,
                          prevEntryDate, minEntryHeight * .9),
                    ));
              },
            );
          }),
    );
  }
}
