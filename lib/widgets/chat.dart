import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nimbus/openai.dart';

import 'package:nimbus/widgets/common.dart';

import '../user_store.dart';

class ChatPage extends StatefulWidget {
  final Chat? chat; // Make chat optional
  const ChatPage([this.chat]); // Allow chat

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String input = "";
  List<Message> allMessages = [];
  late Chat chat;
  final TextEditingController _controller = TextEditingController();

  Future<void> sendMessage() async {
    final emptyChat = widget.chat == null && allMessages.isEmpty;
    if (emptyChat) await UserStore.instance.saveChat(chat);
    final userMessage = new Message(content: input);
    allMessages.add(userMessage);
    _controller.clear(); // needed for enter submission
    input = "";
    setState(() {});
    await UserStore.instance.addMessage(chat, userMessage);
    final gptMessage = await OpenAIClient.instance.chatComplete(allMessages);
    allMessages.add(gptMessage);
    await UserStore.instance.addMessage(chat, gptMessage);
  }

  @override
  void initState() {
    super.initState();
    if (widget.chat == null) {
      chat = Chat();
    } else {
      chat = widget.chat!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emptyChat = widget.chat == null && allMessages.isEmpty;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CommonAppBar(emptyChat: emptyChat),
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
                child: emptyChat
                    ? Text("")
                    : FirestoreQueryBuilder<Message>(
                        query: UserStore.instance.readChatMessages(chat),
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
                                return ListTile(
                                    // Indent based on the sender
                                    contentPadding: EdgeInsets.only(
                                      left: isUser ? 50 : 0,
                                      right: isUser ? 0 : 50,
                                    ),
                                    leading: Icon(Icons.message, size: 20),
                                    title: Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text(message.content),
                                    ));
                              });
                        })),
            TextField(
              controller: _controller,
              onChanged: (text) {
                // rerender only when send button needs it
                if (text.isNotEmpty && input.isEmpty ||
                    text.isEmpty && input.isNotEmpty) {
                  input = text;
                  setState(() {});
                } else {
                  input = text;
                }
              },
              onSubmitted: (text) async {
                // Fires when the user presses the enter key
                if (input.isNotEmpty) await sendMessage();
              },
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: InputBorder.none, // Remove the underline
                suffixIcon: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: input.isNotEmpty ? () => sendMessage() : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
