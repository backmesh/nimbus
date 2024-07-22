import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:nimbus/widgets/appbar.dart';
import 'package:nimbus/widgets/audio_entry.dart';
import 'package:nimbus/widgets/expandable_fab.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import 'package:nimbus/widgets/entry.dart';

import '../user_store.dart';

class EntriesPage extends StatefulWidget {
  final Map<String, Tag> tags;
  const EntriesPage(this.tags);

  @override
  _EntriesPageState createState() => _EntriesPageState();
}

class _EntriesPageState extends State<EntriesPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return FirestoreQueryBuilder<Entry>(
      query: UserStore.instance.readEntries(),
      builder: (context, snapshot, _) {
        if (snapshot.isFetching) {
          return Center(child: CircularProgressIndicator());
        }

        final itemCount = snapshot.docs.length;
        return ListView.builder(
          itemCount: itemCount,
          itemBuilder: (context, index) {
            final QueryDocumentSnapshot<Entry> doc = snapshot.docs[index];
            final Entry entry = doc.data();
            final docSummary = entry.doc.isEmpty()
                ? ""
                : entry.doc
                        .getPlainText(0, min(20, entry.doc.length))
                        .replaceAll("\n", "")
                        .toString() +
                    "...";
            final textStyle = TextStyle(fontSize: 12, color: Color(0xFF606A85));
            return ListTile(
              title: Text(docSummary, style: textStyle),
              subtitle: Text(localizations.formatShortDate(entry.date)),
              onTap: () async {
                await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          EntryPage(widget.tags, doc.id, entry),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return child; // No animation
                      },
                    ));
              },
            );
          },
        );
      },
    );
  }
}

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
      drawer: Drawer(
        child: Column(
          children: [
            Expanded(
              child: EntriesPage(widget.tags),
            ),
          ],
        ),
      ),
      floatingActionButton: ExpandableFab(
        distance: 80,
        children: [
          ActionButton(
            onPressed: () async {
              await Posthog().capture(eventName: 'ViewEntry', properties: {
                'newEntry': true,
                'hasAudio': false,
              });
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => EntryPage(widget.tags,
                        DateTime.now().toIso8601String(), new Entry())),
              );
              await Posthog().capture(eventName: 'BackFromEntry', properties: {
                'newEntry': true,
                'hasAudio': false,
              });
            },
            icon: const Icon(Icons.keyboard),
          ),
          ActionButton(
            onPressed: () async {
              await Posthog().capture(eventName: 'ViewEntry', properties: {
                'newEntry': true,
                'hasAudio': true,
              });
              final entryKey = DateTime.now().toIso8601String();
              final entry = Entry();
              final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AudioEntryPage(widget.tags, entryKey, entry),
                  ));
              if (result != 'deleted')
                await UserStore.instance.backupLocalRecording(entryKey, entry);
              await Posthog().capture(eventName: 'BackFromEntry', properties: {
                'newEntry': true,
                'hasAudio': true,
              });
            },
            icon: const Icon(Icons.mic),
          ),
        ],
      ),
      appBar: CustomAppBar(),
      body:
          EntryPage(widget.tags, DateTime.now().toIso8601String(), new Entry()),
    );
  }
}
