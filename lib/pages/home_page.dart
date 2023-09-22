import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
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
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScrollableJournal(context),
    );
  }

  bool _isTodaySelected() {
    return _date.toString().substring(0, 10) ==
        DateTime.now().toString().substring(0, 10);
  }

  Widget _buildScrollableJournal(BuildContext context) {
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);

    var dateText =
        _isTodaySelected() ? 'Today' : localizations.formatShortDate(_date);

    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(children: [
            Center(child: Text(dateText)),
            IconButton(
              icon: Icon(Icons.date_range),
              padding: EdgeInsets.zero,
              onPressed: () async {
                DateTime? newDate = await showDatePicker(
                    context: context,
                    initialEntryMode: DatePickerEntryMode.calendarOnly,
                    initialDate: _date,
                    firstDate: DateTime(2010),
                    lastDate: DateTime.now());
                if (newDate == null) return;
                setState(() {
                  _date = newDate;
                });
              },
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
                    final currDate = _date.subtract(Duration(days: index));
                    late Entry entry;
                    if (snapshot.hasMore) snapshot.fetchMore();
                    entry = snapshot.docs.map((d) => d.data()).firstWhere(
                        (e) => sameCalendarDay(e.date, currDate),
                        orElse: () => Entry(doc: Document(), date: currDate));
                    double screenHeight = MediaQuery.of(context).size.height;
                    double desiredHeight = screenHeight * 0.8;
                    return Container(
                      child: EntryPage(entry, widget.uid),
                      height: desiredHeight,
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
