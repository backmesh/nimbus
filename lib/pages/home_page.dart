import 'package:flutter/material.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';

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
                  itemCount: snapshot.docs.length,
                  itemBuilder: (context, index) {
                    //if (snapshot.hasMore) snapshot.fetchMore();
                    double screenHeight = MediaQuery.of(context).size.height;
                    double desiredHeight = screenHeight * 0.8;
                    final entry = snapshot.docs[index].data();
                    final yesterday =
                        entry.date.subtract(Duration(days: index));
                    // undbounded calendar widget into the past
                    final prevSnapshot = index == 0
                        ? null
                        : snapshot.docs.elementAtOrNull(index - 1);
                    if (prevSnapshot == null) {
                      return ConstrainedBox(
                        constraints: BoxConstraints(minHeight: desiredHeight),
                        child: EntryPage(entry, widget.uid),
                      );
                    }
                    // bounded calendar widget
                    final prevEntry = prevSnapshot.data();
                    if (!sameCalendarDay(yesterday, prevEntry.date)) {}
                    // consecutive days so no calendar widget
                    return ConstrainedBox(
                      constraints: BoxConstraints(minHeight: desiredHeight),
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
