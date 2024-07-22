import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nimbus/widgets/common.dart';

import '../user_store.dart';

class ChatPage extends StatefulWidget {
  final Chat chat;
  const ChatPage(this.chat);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CommonAppBar(),
      drawer: CommonDrawer(),
      body: Container(
        padding: EdgeInsets.only(
          top: 75,
          bottom: 25,
          left: 25,
          right: 25,
        ),
        child: Column(
          children: [
            Expanded(
                child: FirestoreQueryBuilder<Message>(
                    query: UserStore.instance.readChatMessages(widget.chat),
                    builder: (context, snapshot, _) {
                      if (snapshot.isFetching) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final itemCount = snapshot.docs.length;

                      return ListView.builder(
                          itemCount: itemCount,
                          itemBuilder: (context, index) {
                            final QueryDocumentSnapshot<Message> doc =
                                snapshot.docs[index];
                            final Message message = doc.data();
                            final isUser = message.model?.isEmpty ?? true;
                            return KeyedSubtree(
                                // Unique key for each item to keep the list in right order
                                key: ValueKey(doc.id),
                                child: ListTile(
                                    // Indent based on the sender
                                    contentPadding: EdgeInsets.only(
                                      left: isUser ? 50 : 0,
                                      right: isUser ? 0 : 50,
                                    ),
                                    leading: Icon(Icons.message, size: 20),
                                    title: Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text(message.content),
                                    )));
                          });
                    })),
            TextField(
              controller: _controller,
              onChanged: (text) {
                setState(() {}); // Trigger rebuild to show/hide suffix icon
              },
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: InputBorder.none, // Remove the underline
                suffixIcon: _controller.text.isEmpty
                    ? Text("")
                    : IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () async {
                          await UserStore.instance.addMessage(widget.chat,
                              new Message(content: _controller.text));
                          setState(() {
                            _controller.clear(); // Clear input field
                          });
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
