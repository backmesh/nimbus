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

class Journalist {
  // ignore subcollection for now
  // final List<Entry> entries;
  final List<String> tags;

  Journalist({required this.tags});

  Journalist.fromDb(Map<String, Object?> json)
      : this(
          tags: (json['tags'] ?? []) as List<String>,
        );

  Map<String, Object?> toDb() {
    return {'tags': tags};
  }
}

// TODO make sure transformations always use 00:00 UTC time
class Entry {
  final Document doc;
  final DateTime date;
  final List<String> tags;

  Entry({required this.doc, required this.date, required this.tags});

  Entry.fromDbCollection(Map<String, Object?> json)
      : this(
          doc: _deltaToDoc(json['delta']! as String),
          date: (json['date']! as Timestamp).toDate(),
          tags: (json['tags'] ?? []) as List<String>,
        );

  Map<String, Object?> toDb() {
    return {'delta': _docToDelta(doc), 'date': Timestamp.fromDate(date)};
  }

  Entry fromNewDoc(Document newDoc) {
    return Entry(date: date, doc: newDoc, tags: tags);
  }
}

class EntryStore {
  final String uid;
  final Stream<DocumentSnapshot<Journalist>> userStream;

  static EntryStore? _instance;

  EntryStore._(this.uid, this.userStream);

  factory EntryStore(String uid) {
    final stream = FirebaseFirestore.instance
        .doc('journalists/${uid}')
        .withConverter<Journalist>(
          fromFirestore: (snapshot, _) => Journalist.fromDb(snapshot.data()!),
          toFirestore: (user, _) => user.toDb(),
        )
        .snapshots();
    _instance ??= EntryStore._(uid, stream);
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
