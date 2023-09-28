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

  IconButton _getDatePickerSeparator(
      FirestoreQueryBuilderSnapshot<Entry> snapshot,
      DateTime upperBound,
      DateTime lowerBound) {
    final start = lowerBound.add(Duration(days: 1));
    final end = upperBound.subtract(Duration(days: 1));
    return IconButton(
      icon: Icon(Icons.add),
      padding: EdgeInsets.all(50),
      onPressed: () async {
        DateTime? newDate = await showDatePicker(
            context: context,
            confirmText: 'CREATE ENTRY',
            initialEntryMode: DatePickerEntryMode.calendarOnly,
            firstDate: start,
            initialDate: end,
            currentDate: end,
            lastDate: end);
        if (newDate == null) return;
        await EntryStore.write(
            widget.uid, Entry(date: newDate, doc: Document()), true);
        snapshot.fetchMore();
      },
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
                final today = DateTime.now();
                final lastEntry = snapshot.docs.firstOrNull?.data();
                final todayOffset = lastEntry != null &&
                        isSameCalendarDay(today, lastEntry.date)
                    ? 0
                    : 1;
                final itemCount = snapshot.docs.length + todayOffset;
                print('todayOffset');
                print(todayOffset);
                print('snapshot.docs.length');
                print(snapshot.docs.length);
                return Column(children: [
                  Expanded(
                      child: ListView.builder(
                    reverse: true,
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (snapshot.hasMore) snapshot.fetchMore();
                      // ignore indexes too large
                      print(index);
                      //if (index >= max(1, snapshot.docs.length)) return null;
                      // today
                      final Entry entry =
                          snapshot.docs.elementAtOrNull(index)?.data() ??
                              Entry(doc: Document(), date: today);

                      final List<Widget> children = [];
                      // first separator, unbounded calendar into the past
                      if (index == itemCount - 1) {
                        children.add(_getDatePickerSeparator(
                            snapshot, entry.date, DateTime(2010)));
                      }
                      // bounded calendar widget
                      final Entry? prevEntry =
                          snapshot.docs.elementAtOrNull(index + 1)?.data();
                      if (prevEntry != null) {
                        final consecutiveDays = isSameCalendarDay(
                            prevEntry.date.add(Duration(days: 1)), entry.date);
                        if (!consecutiveDays)
                          children.add(_getDatePickerSeparator(
                              snapshot, entry.date, prevEntry.date));
                      }
                      children.add(EntryPage(entry, widget.uid));
                      // today
                      // if (index == 0 && !isSameCalendarDay(entry.date, today)) {
                      //   children.add(EntryPage(
                      //       Entry(doc: Document(), date: today), widget.uid));
                      // }
                      return ConstrainedBox(
                        constraints: BoxConstraints(minHeight: minEntryHeight),
                        child: Column(children: children),
                      );
                    },
                  )),
                ]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
