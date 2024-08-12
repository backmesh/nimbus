import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:nimbus/widgets/common.dart';

import '../user_store.dart';

class ChatListPage extends StatefulWidget {
  final Chat? chat;

  ChatListPage({required this.chat});

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

        if (snapshot.hasError) {
          // TODO display with better UX as snack
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final itemCount = snapshot.docs.length + (snapshot.hasMore ? 1 : 0);
        return ListView.builder(
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index == snapshot.docs.length) {
              snapshot.fetchMore();
              return Center(child: CircularProgressIndicator());
            }

            final QueryDocumentSnapshot<Chat> doc = snapshot.docs[index];
            final Chat chat = doc.data();
            final isHighlighted =
                widget.chat != null && chat.docKey() == widget.chat!.docKey();
            return ListTile(
                title: Text(localizations.formatShortDate(chat.date)),
                tileColor: isHighlighted
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : null, // Highlighted background color
                onTap: () => pushChatPage(context, chat));
          },
        );
      },
    );
  }
}
