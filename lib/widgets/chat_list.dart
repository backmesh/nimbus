import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:nimbus/widgets/chat.dart';

import '../user_store.dart';

class ChatListPage extends StatefulWidget {
  @override
  _EntriesPageState createState() => _EntriesPageState();
}

class _EntriesPageState extends State<ChatListPage> {
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
            final docSummary = doc.id;
            final textStyle = TextStyle(fontSize: 12, color: Color(0xFF606A85));
            return ListTile(
              title: Text(docSummary, style: textStyle),
              subtitle: Text(localizations.formatShortDate(entry.date)),
              onTap: () async {
                await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          ChatPage(doc.id, entry),
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
