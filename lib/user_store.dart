import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:cloud_firestore/cloud_firestore.dart';

String _formatDate(DateTime date) => date.toString().substring(0, 10);

bool isSameCalendarDay(DateTime a, DateTime b) =>
    _formatDate(a) == _formatDate(b);

bool isToday(DateTime a) => isSameCalendarDay(a, DateTime.now());

List<String> _tagsMapper(Object? jsonField) => jsonField != null
    ? (jsonField as List<dynamic>).cast<String>()
    : [].cast<String>();

class Journalist {
  // ignore subcollection for now
  // final List<Entry> entries;
  final List<String> tags;

  Journalist({required this.tags});

  Journalist.fromDb(Map<String, Object?> json)
      : this(
          tags: _tagsMapper(json['tags']),
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
          tags: _tagsMapper(json['tags']),
        );

  Map<String, Object?> toDb() {
    return {
      'delta': _docToDelta(doc),
      'date': Timestamp.fromDate(date),
      'tags': tags
    };
  }

  Entry fromNewDoc(Document newDoc) {
    return Entry(date: date, doc: newDoc, tags: tags);
  }

  static Document _deltaToDoc(String delta) {
    return Document.fromDelta(Delta.fromJson(jsonDecode(delta)));
  }

  static String _docToDelta(Document doc) {
    return jsonEncode(doc.toDelta().toJson());
  }
}

class UserStore {
  final String uid;
  final DocumentReference<Journalist> userRef;
  final CollectionReference<Entry> entriesRef;

  static UserStore? _instance;

  UserStore._(this.uid, this.userRef, this.entriesRef);

  factory UserStore(String uid) {
    final userRef = FirebaseFirestore.instance
        .doc('journalists/${uid}')
        .withConverter<Journalist>(
          fromFirestore: (snapshot, _) => Journalist.fromDb(snapshot.data()!),
          toFirestore: (user, _) => user.toDb(),
        );
    final entriesRef = FirebaseFirestore.instance
        .collection('journalists/${uid}/entries')
        .withConverter<Entry>(
          fromFirestore: (snapshot, _) =>
              Entry.fromDbCollection(snapshot.data()!),
          toFirestore: (entry, _) => entry.toDb(),
        );
    _instance ??= UserStore._(uid, userRef, entriesRef);
    return _instance!;
  }

  static UserStore get instance {
    assert(_instance != null, 'UserStore must be initialized before accessing');
    return _instance!;
  }

  Query<Entry> readEntries() {
    return entriesRef.orderBy('date', descending: true);
  }

  Future<void> deleteEntry(Entry entry) async {
    final key = _formatDate(entry.date);
    entriesRef.doc(key).delete();
  }

  Future<void> createEntry(Entry entry) async {
    final key = _formatDate(entry.date);
    await entriesRef.doc(key).set(entry);
  }

  Future<void> updateEntry(Entry entry) async {
    final key = _formatDate(entry.date);
    try {
      await entriesRef.doc(key).update(entry.toDb());
    } catch (e) {
      if (e is FirebaseException &&
          e.code == 'not-found' &&
          isToday(entry.date)) {
        // today is a special case
        return await entriesRef.doc(key).set(entry);
      }
      throw e;
    }
  }

  Future<void> updateUser(Journalist user) async {
    await userRef.update(user.toDb());
  }
}
