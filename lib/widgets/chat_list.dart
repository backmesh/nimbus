import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:nimbus/widgets/common.dart';

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
            final textStyle = TextStyle(color: Color(0xFF606A85), fontSize: 15);
            return ListTile(
                title: Text(localizations.formatShortDate(chat.date),
                    style: textStyle),
                onTap: () => pushChatPage(context, chat));
          },
        );
      },
    );
  }
}
