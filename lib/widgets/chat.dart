import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nimbus/openai.dart';

import 'package:nimbus/widgets/common.dart';

import '../user_store.dart';

class ChatPage extends StatefulWidget {
  final Chat chat;
  const ChatPage(this.chat);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String input = "";
  List<Message> allMessages = [];

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

                      if (snapshot.hasMore) snapshot.fetchMore();

                      final itemCount = snapshot.docs.length;
                      allMessages =
                          snapshot.docs.map((doc) => doc.data()).toList();

                      return ListView.builder(
                          itemCount: itemCount,
                          itemBuilder: (context, index) {
                            final Message message = allMessages[index];
                            final isUser = message.model?.isEmpty ?? true;
                            return KeyedSubtree(
                                // Unique key for each item to keep the list in right order
                                key: ValueKey(message.docKey()),
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
              onChanged: (text) {
                setState(() {
                  input = text;
                });
              },
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: InputBorder.none, // Remove the underline
                suffixIcon: input.isEmpty
                    ? Text("")
                    : IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () async {
                          final userMessage = new Message(content: input);
                          allMessages.add(userMessage);
                          setState(() {
                            input = "";
                          });
                          await UserStore.instance
                              .addMessage(widget.chat, userMessage);
                          final gptMessagee = await OpenAIClient.instance
                              .chatComplete(allMessages);
                          await UserStore.instance
                              .addMessage(widget.chat, gptMessagee);
                          setState(() {
                            allMessages.clear();
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
