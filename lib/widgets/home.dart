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
      body: _buildScrollableJournal(context),
    );
  }

  Widget _getDatePickerSeparator(FirestoreQueryBuilderSnapshot<Entry> snapshot,
      DateTime upperBound, DateTime lowerBound) {
    final start = lowerBound.add(Duration(days: 1));
    final end = upperBound.subtract(Duration(days: 1));
    return GestureDetector(
      child: Card(
          child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 50, horizontal: 500),
              child: Icon(Icons.add))),
      onTap: () async {
        DateTime? newDate = await showDatePicker(
            context: context,
            confirmText: 'Create Entry',
            initialEntryMode: DatePickerEntryMode.calendarOnly,
            firstDate: start,
            initialDate: end,
            currentDate: end,
            lastDate: end);
        if (newDate == null) return;
        await UserStore.instance
            .createEntry(Entry(date: newDate, doc: Document(), tagIds: []));
      },
    );
  }

  Widget _buildScrollableJournal(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Container(
                  margin: const EdgeInsets.only(right: 10.0),
                  child: IconButton(
                    icon: Icon(Icons.more_horiz),
                    // TODO show settings
                    // add signout
                    // add delete account + data
                    onPressed: () async {},
                  ))
            ]),
          ),
          Expanded(
            flex: 9,
            child: FirestoreQueryBuilder<Entry>(
              query: UserStore.instance.readEntries(),
              builder: (context, snapshot, _) {
                // Loading
                if (snapshot.isFetching) {
                  return Center(child: CircularProgressIndicator());
                }
                final today = getToday();
                final lastEntry = snapshot.docs.firstOrNull?.data();
                final todayOffset = lastEntry != null &&
                        isSameCalendarDay(today, lastEntry.date)
                    ? 0
                    : 1;
                final itemCount = snapshot.docs.length + todayOffset;
                double minEntryHeight = screenHeight / itemCount;
                // Logger.debug('todayOffset');
                // Logger.debug(todayOffset);
                // Logger.debug('snapshot.docs.length');
                // Logger.debug(snapshot.docs.length);
                return Column(children: [
                  Expanded(
                      child: ListView.builder(
                    reverse: true,
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (snapshot.hasMore) snapshot.fetchMore();
                      // index 0 is today
                      final Entry entry = todayOffset == 1 && index == 0
                          ? Entry(doc: Document(), date: today, tagIds: [])
                          : snapshot.docs[index - todayOffset].data();
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
                      children.add(EntryPage(widget.tags, entry));
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
