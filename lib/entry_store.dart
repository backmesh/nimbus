import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:cloud_firestore/cloud_firestore.dart';

Document _deltaToDoc(String delta) {
  return Document.fromDelta(Delta.fromJson(jsonDecode(delta)));
}

String _docToDelta(Document doc) {
  return jsonEncode(doc.toDelta().toJson());
}

bool sameCalendarDay(DateTime a, DateTime b) {
  return a.toString().substring(0, 10) == b.toString().substring(0, 10);
}

String getHumanReadableDate(DateTime date) {
  // Get the month name from the DateTime object
  String monthName = '';
  switch (date.month) {
    case 1:
      monthName = 'January';
      break;
    case 2:
      monthName = 'February';
      break;
    case 3:
      monthName = 'March';
      break;
    case 4:
      monthName = 'April';
      break;
    case 5:
      monthName = 'May';
      break;
    case 6:
      monthName = 'June';
      break;
    case 7:
      monthName = 'July';
      break;
    case 8:
      monthName = 'August';
      break;
    case 9:
      monthName = 'September';
      break;
    case 10:
      monthName = 'October';
      break;
    case 11:
      monthName = 'November';
      break;
    case 12:
      monthName = 'December';
      break;
  }

  return '$monthName ${date.day}, ${date.year}';
}

// TODO make sure transformations always use 00:00 UTC time
class Entry {
  final Document doc;
  final DateTime date;

  Entry({required this.doc, required this.date});

  Entry.fromDbCollection(Map<String, Object?> json)
      : this(
          doc: _deltaToDoc(json['delta']! as String),
          date: (json['date']! as Timestamp).toDate(),
        );

  Map<String, Object?> toDb() {
    return {'delta': _docToDelta(doc), 'date': Timestamp.fromDate(date)};
  }

  Entry fromDoc(Document newDoc) {
    return Entry(date: date, doc: newDoc);
  }
}

class EntryStore {
  static final CollectionReference _users =
      FirebaseFirestore.instance.collection('journalists');

  static CollectionReference<Entry> readAll(String uid) {
    return FirebaseFirestore.instance
        .collection('journalists/${uid}/entries')
        .withConverter<Entry>(
          fromFirestore: (snapshot, _) =>
              Entry.fromDbCollection(snapshot.data()!),
          toFirestore: (entry, _) => entry.toDb(),
        );
  }

  static Future<void> write(String uid, Entry? entry) async {
    if (entry == null) return;
    if (entry.doc.isEmpty())
      return _users.doc(_entryKey(uid, entry.date)).delete();
    final val = entry.toDb();
    if (val['delta'] == '') return;
    await _users.doc(_entryKey(uid, entry.date)).set(val);
  }

  // TODO use withConverter or remove
  // static Future<Entry?> read(String uid, DateTime date) async {
  //   final snapshot = _users.doc(_entryKey(uid, date));
  //   final entry = await snapshot.get();
  //   if (!entry.exists) return null;
  //   final delta = entry.get('delta');
  //   if (delta == null) return null;
  //   return Entry(
  //       doc: _deltaToDoc(delta),
  //       date: (entry.get('date')! as Timestamp).toDate());
  // }

  static String _entryKey(String uid, DateTime date) {
    return '${uid}/entries/${date.toString().substring(0, 10)}';
  }
}
