import 'dart:convert';
import 'dart:io';

import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Tag {
  final String name;

  Tag({required this.name});

  static List<String> getNames(List<Tag> tags) {
    return tags.map((tag) => tag.name).toList();
  }

  Tag.fromDb(String key, Map<String, Object?> json)
      : this(
          name: json['name']! as String,
        );

  Map<String, Object?> toDb() {
    return {
      'name': name,
    };
  }
}

class Entry {
  final DateTime date;
  final Document doc;
  final String recording;
  final List<String> tagIds;

  Entry(
      {Document? doc, DateTime? date, List<String>? tagIds, String? recording})
      : this.doc = doc ?? Document(),
        this.tagIds = tagIds ?? [].cast<String>(),
        this.recording = recording ?? "",
        this.date = date ?? DateTime.now();

  static List<String> _tagIdsMapper(Object? jsonField) => jsonField != null
      ? (jsonField as List<dynamic>).cast<String>()
      : [].cast<String>();

  Entry.fromDb(Map<String, Object?> json)
      : this(
            doc: json.containsKey('delta')
                ? _deltaToDoc(json['delta']! as String)
                : Document(),
            date: (json['date']! as Timestamp).toDate(),
            tagIds: _tagIdsMapper(json['tagIds']),
            recording: json.containsKey('recording')
                ? json['recording']! as String
                : "");

  Map<String, Object?> toDb() {
    return {
      'delta': _docToDelta(doc),
      'date': Timestamp.fromDate(date),
      'tagIds': tagIds,
      'recording': recording,
    };
  }

  bool hasAudio() {
    return recording.isNotEmpty;
  }

  Entry fromNewDoc(Document newDoc) {
    return Entry(date: date, doc: newDoc, tagIds: tagIds);
  }

  Entry fromRecording(String recording) {
    return Entry(date: date, recording: recording, tagIds: tagIds);
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
  final CollectionReference<Entry> entriesRef;
  final CollectionReference<Tag> tagsRef;

  static UserStore? _instance;

  UserStore._(this.uid, this.entriesRef, this.tagsRef);

  factory UserStore(String uid) {
    final tagsRef = FirebaseFirestore.instance
        .collection('journalists/${uid}/tags')
        .withConverter<Tag>(
          fromFirestore: (snapshot, _) =>
              Tag.fromDb(snapshot.id, snapshot.data()!),
          toFirestore: (tag, _) => tag.toDb(),
        );
    final entriesRef = FirebaseFirestore.instance
        .collection('journalists/${uid}/entries')
        .withConverter<Entry>(
          fromFirestore: (snapshot, _) {
            return Entry.fromDb(snapshot.data()!);
          },
          toFirestore: (entry, _) => entry.toDb(),
        );
    _instance ??= UserStore._(uid, entriesRef, tagsRef);
    return _instance!;
  }

  static void clear() {
    _instance = null;
  }

  static UserStore get instance {
    assert(_instance != null, 'UserStore must be initialized before accessing');
    return _instance!;
  }

  Query<Entry> readEntries() {
    return entriesRef.orderBy('date', descending: true);
  }

  Future<void> deleteEntry(String entryKey, Entry entry) async {
    await entriesRef.doc(entryKey).delete();
    if (entry.hasAudio()) {
      final localPath = await _getLocalRecordingPath(entryKey);
      File file = File(localPath);
      if (await file.exists()) file.delete();
      await FirebaseStorage.instance
          .ref(_getCloudRecordingPath(entryKey))
          .delete();
    }
  }

  Future<void> saveEntry(String entryKey, Entry entry) async {
    await entriesRef.doc(entryKey).set(entry);
  }

  // Future<bool> hasEntry(String entryKey) async {
  //   final snapshot = await entriesRef.doc(entryKey).get();
  //   return snapshot.data() != null;
  // }

  Future<DocumentReference<Tag>> newTag(Tag tag) async {
    return await tagsRef.add(tag);
  }

  static Future<String> _getLocalRecordingPath(String entryKey) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/${entryKey}.m4a';
  }

  String _getCloudRecordingPath(String entryKey) {
    return 'recordings/${UserStore.instance.uid}/${entryKey}.m4a';
  }

  Future<void> backupLocalRecording(String entryKey, Entry entry) async {
    final localPath = await _getLocalRecordingPath(entryKey);
    File file = File(localPath);
    if (await file.exists()) {
      final cloudStoragePath = _getCloudRecordingPath(entryKey);
      await FirebaseStorage.instance.ref(cloudStoragePath).putFile(file);
      await UserStore.instance
          .saveEntry(entryKey, entry.fromRecording(cloudStoragePath));
      await file.delete();
    }
  }

  Future<String> setupLocalRecording(String entryKey, Entry entry) async {
    final localPath = await _getLocalRecordingPath(entryKey);
    if (entry.hasAudio()) {
      final cloudStoragePath = _getCloudRecordingPath(entryKey);
      File file = File(localPath);
      await FirebaseStorage.instance.ref(cloudStoragePath).writeToFile(file);
    }
    return localPath;
  }
}
