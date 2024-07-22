import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:nimbus/widgets/chat.dart';

import '../user_store.dart';

class ChatListPage extends StatefulWidget {
  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return FirestoreQueryBuilder<Chat>(
      query: UserStore.instance.readChats(),
      builder: (context, snapshot, _) {
        if (snapshot.isFetching) {
          return Center(child: CircularProgressIndicator());
        }

        final itemCount = snapshot.docs.length;
        return ListView.builder(
          itemCount: itemCount,
          itemBuilder: (context, index) {
            final QueryDocumentSnapshot<Chat> doc = snapshot.docs[index];
            final Chat chat = doc.data();
            final docSummary = doc.id;
            final textStyle = TextStyle(fontSize: 12, color: Color(0xFF606A85));
            return ListTile(
              title: Text(docSummary, style: textStyle),
              subtitle: Text(localizations.formatShortDate(chat.date)),
              onTap: () async {
                await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          ChatPage(doc.id, chat),
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
