import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:cloud_firestore/cloud_firestore.dart';

Document _deltaToDoc(String delta) {
  return Document.fromDelta(Delta.fromJson(jsonDecode(delta)));
}

String _docToDelta(Document doc) {
  return jsonEncode(doc.toDelta().toJson());
}

bool isSameCalendarDay(DateTime a, DateTime b) {
  return a.toString().substring(0, 10) == b.toString().substring(0, 10);
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
  final String uid;

  static EntryStore? _instance;

  EntryStore._(this.uid);

  factory EntryStore(String uid) {
    _instance ??= EntryStore._(uid);
    return _instance!;
  }

  static EntryStore get instance {
    assert(
        _instance != null, 'EntryStore must be initialized before accessing');
    return _instance!;
  }

  Query<Entry> readAll() {
    return FirebaseFirestore.instance
        .collection('journalists/${uid}/entries')
        .orderBy('date', descending: true)
        .withConverter<Entry>(
          fromFirestore: (snapshot, _) =>
              Entry.fromDbCollection(snapshot.data()!),
          toFirestore: (entry, _) => entry.toDb(),
        );
  }

  Future<void> delete(Entry entry) async {
    final key = _entryKey(entry.date);
    FirebaseFirestore.instance
        .collection('journalists/${uid}/entries')
        .doc(key)
        .delete();
  }

  Future<void> create(Entry entry) async {
    final key = _entryKey(entry.date);
    final val = entry.toDb();
    await FirebaseFirestore.instance
        .collection('journalists/${uid}/entries')
        .doc(key)
        .set(val);
  }

  Future<void> update(Entry entry) async {
    final key = _entryKey(entry.date);
    final val = entry.toDb();
    await FirebaseFirestore.instance
        .collection('journalists/${uid}/entries')
        .doc(key)
        .update(val);
  }

  String _entryKey(DateTime date) {
    return '${uid}/entries/${date.toString().substring(0, 10)}';
  }
}
