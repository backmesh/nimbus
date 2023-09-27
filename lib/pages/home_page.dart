import 'package:flutter/material.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;

import '../entry_store.dart';
import 'entry_page.dart';

class HomePage extends StatefulWidget {
  final String uid;
  const HomePage(this.uid);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScrollableJournal(context),
    );
  }

  Widget _buildScrollableJournal(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double minEntryHeight = screenHeight * 0.2;
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(children: [
            IconButton(
              icon: Icon(Icons.settings),
              padding: EdgeInsets.zero,
              // TODO show settings
              onPressed: () async {},
            ),
          ]),
          Expanded(
            child: FirestoreQueryBuilder<Entry>(
              query: EntryStore.readAll(widget.uid),
              builder: (context, snapshot, _) {
                // Loading
                if (snapshot.isFetching) {
                  return Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  reverse: true,
                  itemBuilder: (context, index) {
                    // ignore indexes too large
                    if (index >= snapshot.docs.length) return null;
                    // handle very first iteration which is the last entry
                    if (index == 0) {
                      final lastEntry = snapshot.docs[0].data();
                      // return empty today if the last entry *was* not for today
                      if (isSameCalendarDay(DateTime.now(), lastEntry.date)) {
                        return null;
                      }
                      return ConstrainedBox(
                        constraints: BoxConstraints(minHeight: minEntryHeight),
                        child: EntryPage(
                            Entry(date: DateTime.now(), doc: Document()),
                            widget.uid),
                      );
                    }
                    final entry = snapshot.docs[index].data();
                    //if (snapshot.hasMore) snapshot.fetchMore();
                    final yesterday =
                        entry.date.subtract(Duration(days: index));
                    // undbounded calendar widget into the past
                    final prevSnapshot = index == 0
                        ? null
                        : snapshot.docs.elementAtOrNull(index - 1);
                    if (prevSnapshot == null) {
                      return ConstrainedBox(
                        constraints: BoxConstraints(minHeight: minEntryHeight),
                        child: EntryPage(entry, widget.uid),
                      );
                    }
                    // bounded calendar widget
                    final prevEntry = prevSnapshot.data();
                    if (!isSameCalendarDay(yesterday, prevEntry.date)) {}
                    // consecutive days so no calendar widget
                    return ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minEntryHeight),
                      child: EntryPage(entry, widget.uid),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
