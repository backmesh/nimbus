import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nimbus/open_ai.dart';

import 'package:nimbus/widgets/common.dart';
import 'package:nimbus/widgets/input.dart';

import '../user_store.dart';

class ChatPage extends StatefulWidget {
  final Chat? chat; // Make chat optional
  const ChatPage([this.chat]); // Allow chat

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late Chat chat;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _userHasScrolled = false;

  Future<void> sendMessage(List<Message> allMessages, String text) async {
    final emptyChat = widget.chat == null && allMessages.isEmpty;
    if (emptyChat) await UserStore.instance.saveChat(chat);
    final userMessage = new Message(content: text);
    allMessages.add(userMessage);
    await UserStore.instance.addMessage(chat, userMessage);
    _userHasScrolled = false;
    scrollToLastMessage();
    final gptMessage = await OpenAIClient.instance.chatComplete(allMessages);
    await UserStore.instance.addMessage(chat, gptMessage);
    scrollToLastMessage();
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection !=
        ScrollDirection.idle) {
      _userHasScrolled = true;
    }
  }

  void scrollToLastMessage() {
    if (_scrollController.hasClients && !_userHasScrolled) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.chat == null) {
      chat = Chat();
    } else {
      chat = widget.chat!;
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FirestoreQueryBuilder<Message>(
        query: UserStore.instance.readChatMessages(chat),
        builder: (context, snapshot, _) {
          if (snapshot.isFetching) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasMore) snapshot.fetchMore();

          final itemCount = snapshot.docs.length;
          final allMessages = snapshot.docs.map((doc) => doc.data()).toList();
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
                      child: ListView.builder(
                          controller: _scrollController,
                          itemCount: itemCount,
                          itemBuilder: (context, index) {
                            // Schedule a post-frame callback to scroll to bottom
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              scrollToLastMessage();
                            });
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
                          })),
                  InputField(sendMessage, allMessages)
                ],
              ),
            ),
          );
        });
  }
}
