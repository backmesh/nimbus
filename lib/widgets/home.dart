import 'dart:math';

import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;

import '../user_store.dart';
import 'entry.dart';

class HomePage extends StatefulWidget {
  final Map<String, Tag> tags;
  const HomePage(this.tags);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white, // To make the AppBar transparent
        toolbarHeight: 40,
        actions: [
          PopupMenuButton<int>(
            icon: Icon(Icons.more_horiz),
            offset: Offset(0, 40),
            onSelected: (value) async {
              // Handle the menu item's value
              switch (value) {
                case 1:
                  await FirebaseUIAuth.signOut();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
              PopupMenuItem<int>(
                  value: 1,
                  child: InkWell(
                      onTap: () {
                        Navigator.pop(context, 1); // Closes the popup menu
                      },
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 18),
                          SizedBox(width: 10),
                          Text('Logout', style: TextStyle(fontSize: 14)),
                        ],
                      ))),
            ],
          ),
        ],
      ),
      body: _buildScrollableJournal(context),
    );
  }

  Widget _buildScrollableJournal(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height * .9;
    return Container(
      padding: EdgeInsets.all(20),
      child: FirestoreQueryBuilder<Entry>(
          query: UserStore.instance.readEntries(),
          builder: (context, snapshot, _) {
            // Loading
            if (snapshot.isFetching || snapshot.isFetchingMore) {
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
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (snapshot.hasMore) snapshot.fetchMore();
                // index 0 is today
                final Entry entry = snapshot.docs[index].data();
                final Entry? prevEntry =
                    snapshot.docs.elementAtOrNull(index + 1)?.data();
                final prevEntryDate =
                    prevEntry != null ? prevEntry.date : DateTime(2010);
                return ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minEntryHeight),
                  child: EntryPage(
                      widget.tags, entry, prevEntryDate, minEntryHeight * .9),
                );
              },
            );
          }),
    );
  }
}
