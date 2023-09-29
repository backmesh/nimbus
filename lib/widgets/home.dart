import 'package:flutter/material.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;

import '../logger.dart';
import '../entry_store.dart';
import 'entry.dart';

class HomePage extends StatefulWidget {
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
        await EntryStore.instance.create(Entry(date: newDate, doc: Document()));
      },
    );
  }

  Widget _buildScrollableJournal(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(children: [
            IconButton(
              icon: Icon(Icons.settings),
              padding: EdgeInsets.zero,
              // TODO show settings
              // add signout
              // add delete account + data
              onPressed: () async {},
            ),
          ]),
          Expanded(
            child: FirestoreQueryBuilder<Entry>(
              query: EntryStore.instance.readAll(),
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
                double minEntryHeight = screenHeight / itemCount;
                Logger.debug('todayOffset');
                Logger.debug(todayOffset);
                Logger.debug('snapshot.docs.length');
                Logger.debug(snapshot.docs.length);
                return Column(children: [
                  Expanded(
                      child: ListView.builder(
                    reverse: true,
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (snapshot.hasMore) snapshot.fetchMore();
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
                      children.add(EntryPage(entry));
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
