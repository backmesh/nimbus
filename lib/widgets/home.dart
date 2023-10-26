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

  Widget _getDatePickerSeparator(FirestoreQueryBuilderSnapshot<Entry> snapshot,
      DateTime upperBound, DateTime lowerBound, double height) {
    final start = lowerBound.add(Duration(days: 1));
    final end = upperBound.subtract(Duration(days: 1));
    return Container(
        height: height * .5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                  width: 1.0,
                  color: Colors.grey[200]!), // Your top border color and width
              bottom: BorderSide(width: 1.0, color: Colors.grey[200]!),
              // Your bottom border color and width
            ),
          ),
          child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0)),
                side: BorderSide(color: Colors.transparent),
              ),
              onPressed: () async {
                DateTime? newDate = await showDatePicker(
                    context: context,
                    confirmText: 'Create Entry',
                    initialEntryMode: DatePickerEntryMode.calendarOnly,
                    firstDate: start,
                    initialDate: end,
                    currentDate: end,
                    lastDate: end);
                if (newDate == null) return;
                await UserStore.instance.createEntry(
                    Entry(date: newDate, doc: Document(), tagIds: []));
              },
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Icon(Icons.add)])),
        ));
  }

  Widget _buildScrollableJournal(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return SafeArea(
      child: FirestoreQueryBuilder<Entry>(
          query: UserStore.instance.readEntries(),
          builder: (context, snapshot, _) {
            // Loading
            if (snapshot.isFetching) {
              return Center(child: CircularProgressIndicator());
            }
            final today = getToday();
            final lastEntry = snapshot.docs.firstOrNull?.data();
            final todayOffset =
                lastEntry != null && isSameCalendarDay(today, lastEntry.date)
                    ? 0
                    : 1;
            final itemCount = snapshot.docs.length + todayOffset;
            double minEntryHeight = screenHeight / 4;
            // Logger.debug('todayOffset');
            // Logger.debug(todayOffset);
            // Logger.debug('snapshot.docs.length');
            // Logger.debug(snapshot.docs.length);
            return ListView.builder(
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
                      snapshot, entry.date, DateTime(2010), minEntryHeight));
                }
                // bounded calendar widget
                final Entry? prevEntry =
                    snapshot.docs.elementAtOrNull(index + 1)?.data();
                if (prevEntry != null) {
                  final consecutiveDays = isSameCalendarDay(
                      prevEntry.date.add(Duration(days: 1)), entry.date);
                  if (!consecutiveDays)
                    children.add(_getDatePickerSeparator(
                        snapshot, entry.date, prevEntry.date, minEntryHeight));
                }
                children.add(EntryPage(widget.tags, entry));
                return ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minEntryHeight),
                  child: Column(children: children),
                );
              },
            );
          }),
    );
  }
}
