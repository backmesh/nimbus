import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:journal/widgets/tags.dart';

import '../user_store.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:journal/widgets/entry.dart';

class EntriesPage extends StatefulWidget {
  final Map<String, Tag> tags;
  const EntriesPage(this.tags);

  @override
  _EntriesPageState createState() => _EntriesPageState();
}

class _EntriesPageState extends State<EntriesPage> {
  late ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    // UserStore.instance.readEntries().snapshots().listen((snapshot) {
    //   for (var change in snapshot.docChanges) {
    //     debugPrint('Doc ${change.doc.id}, change type: ${change.type}');
    //   }
    // });
    final localizations = MaterialLocalizations.of(context);
    return Container(
      padding: EdgeInsets.only(top: 25, bottom: 25, left: 25, right: 25),
      child: FirestoreQueryBuilder<Entry>(
          query: UserStore.instance.readEntries(),
          builder: (context, snapshot, _) {
            // Loading
            if (snapshot.isFetching) {
              return Center(child: CircularProgressIndicator());
            }

            final itemCount = snapshot.docs.length;
            return ListView.builder(
              reverse: true,
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              controller: _controller,
              itemCount: itemCount,
              findChildIndexCallback: (Key key) {
                final valueKey = key as ValueKey<String>;
                return snapshot.docs
                    .indexWhere((doc) => doc.id == valueKey.value);
              },
              itemBuilder: (context, index) {
                // last element and has more, then load
                if (snapshot.hasMore && index == snapshot.docs.length - 1) {
                  snapshot.fetchMore();
                }
                // index 0 is today
                final QueryDocumentSnapshot<Entry> doc = snapshot.docs[index];
                final Entry entry = doc.data();
                return KeyedSubtree(
                    // Unique key for each item to keep the list in right order
                    key: ValueKey(doc.id),
                    child: KeyedSubtree(
                        // Unique key from entry contents so ListView can rebuild when there is a change
                        key: ValueKey(entry.doc.toDelta().toString()),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      EntryPage(widget.tags, doc.id, entry)),
                            );
                          },
                          child: Container(
                              child: Column(children: [
                            Text(entry.doc.isEmpty()
                                ? ""
                                : entry.doc
                                    .getPlainText(0, min(20, entry.doc.length))
                                    .toString()),
                            Row(children: [
                              Text(localizations.formatShortDate(entry.date)),
                              Tags(widget.tags, entry),
                              Icon(Icons.chevron_right),
                            ]),
                          ])),
                        )));
              },
            );
          }),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => EntryPage(
                    widget.tags,
                    DateTime.now().toIso8601String(),
                    new Entry(
                        date: DateTime.now(), doc: Document(), tagIds: []))),
          );
        },
        child: Icon(Icons.add),
      ),
      appBar: AppBar(
        toolbarHeight: 50,
        title: Text("Entries"),
        centerTitle: false,
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
                case 2:
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Delete your account?'),
                        content: const Text(
                            '''If you select Delete we will delete your account permanently.

Your app data will also be deleted and you won't be able to retrieve it.'''),
                        actions: [
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: const Text(
                              'Delete',
                              selectionColor: Colors.red,
                              style: TextStyle(color: Colors.red),
                            ),
                            onPressed: () async {
                              try {
                                User? user = FirebaseAuth.instance.currentUser;
                                await user?.delete();
                              } catch (e) {
                                // TODO Handle exceptions
                              }
                              // Call the delete account function
                            },
                          ),
                        ],
                      );
                    },
                  );
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
              PopupMenuItem<int>(
                  value: 2,
                  child: InkWell(
                      onTap: () {
                        Navigator.pop(context, 2); // Closes the popup menu
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outlined,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 10),
                          Text('Delete Account',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.red)),
                        ],
                      ))),
            ],
          ),
        ],
      ),
      body: EntriesPage(widget.tags),
    );
  }
}
