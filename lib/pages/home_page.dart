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
  final List<DateTime> newDates = [];

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
                    if (snapshot.hasMore) snapshot.fetchMore();
                    final today = DateTime.now();
                    // ignore indexes too large
                    if (index >= snapshot.docs.length) return null;
                    // handle very first iteration which is the last entry
                    if (index == 0) {
                      final lastEntry = snapshot.docs[0].data();
                      // return empty today if the last entry *was* not for today
                      if (isSameCalendarDay(today, lastEntry.date)) return null;
                      return Column(children: [
                        if (!isSameCalendarDay(
                            today.subtract(Duration(days: 1)), lastEntry.date))
                          Text('bounded calendar widget'),
                        ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: minEntryHeight),
                          child: EntryPage(
                              Entry(date: DateTime.now(), doc: Document()),
                              widget.uid),
                        )
                      ]);
                    }
                    final entry = snapshot.docs[index].data();
                    // undbounded calendar widget into the past
                    final prevSnapshot =
                        snapshot.docs.elementAtOrNull(index + 1);
                    if (prevSnapshot == null) {
                      return Column(children: [
                        IconButton(
                          icon: Icon(Icons.add),
                          padding: EdgeInsets.all(50),
                          onPressed: () async {
                            DateTime? newDate = await showDatePicker(
                                context: context,
                                confirmText: 'CREATE ENTRY',
                                initialEntryMode:
                                    DatePickerEntryMode.calendarOnly,
                                initialDate: entry.date,
                                currentDate: entry.date,
                                firstDate: DateTime(2010),
                                lastDate: entry.date);
                            if (newDate == null) return;
                            setState(() {
                              newDates.add(newDate);
                            });
                          },
                        ),
                        ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: minEntryHeight),
                          child: EntryPage(entry, widget.uid),
                        )
                      ]);
                    }
                    // bounded calendar widget
                    final prevEntry = prevSnapshot.data();
                    if (!isSameCalendarDay(
                        entry.date.subtract(Duration(days: 1)),
                        prevEntry.date)) {
                      return Column(children: [
                        Text('bounded calendar widget'),
                        ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: minEntryHeight),
                          child: EntryPage(entry, widget.uid),
                        )
                      ]);
                    }
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
