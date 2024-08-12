import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nimbus/gemini.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:flutter_highlight/themes/a11y-light.dart';

import 'package:nimbus/widgets/common.dart';
import 'package:nimbus/widgets/highlight.dart';
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

  Future<void> sendMessage(
      List<Message> allMessages, Message userMessage) async {
    final emptyChat = widget.chat == null && allMessages.isEmpty;
    if (emptyChat) await UserStore.instance.saveChat(chat);
    await UserStore.instance.saveMessage(chat, userMessage);
    _userHasScrolled = false;
    scrollToLastMessage();
    await GeminiClient.instance
        .chatCompleteStream(allMessages, userMessage)
        .listen((mssg) async {
      await UserStore.instance.saveMessage(chat, mssg);
      scrollToLastMessage();
    });
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
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: CommonAppBar(chat: allMessages.isEmpty ? null : chat),
            drawer: CommonDrawer(chat: allMessages.isEmpty ? null : chat),
            body: Container(
              padding: EdgeInsets.all(25),
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
                            return message.isUser()
                                ? UserMessage(message: message)
                                : AIMessage(message: message, chat: chat);
                          })),
                  const SizedBox(height: 15),
                  InputField(sendMessage, allMessages)
                ],
              ),
            ),
          );
        });
  }
}

class UserMessage extends StatelessWidget {
  final Message message;

  const UserMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.centerRight, // Ensure alignment to the right
        child: FractionallySizedBox(
          widthFactor: 0.7,
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: EdgeInsets.all(15.0), // Add some vertical margin
              padding:
                  EdgeInsets.all(15.0), // Add padding for better appearance
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer, // Background color for user message
                borderRadius: BorderRadius.circular(10.0), // Rounded corners
              ),
              child: SelectableText(message.content),
            ),
          ),
        ));
  }
}

class AIMessage extends StatelessWidget {
  final Message message;
  final Chat chat;

  const AIMessage(
      {required this.message, required this.chat}); // Update constructor

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ListTile(
        leading: Icon(Icons.message, size: 20),
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MarkdownBody(
                data: message.fnCalls.length > 0
                    ? '''```bash
${message.fnCalls.map((f) => f.fnArgs['code']).join('\n')}
                    '''
                    : message.content,
                selectable: true,
                extensionSet: md.ExtensionSet.gitHubWeb,
                builders: {
                  'code': CodeElementBuilder(),
                },
              ),
              SizedBox(height: 10),
              if (message.fnCalls.length > 0 && !message.fnCallsDone())
                FilledButton(
                    // TODO show some loading indicator
                    onPressed: () async {
                      for (var fnC in message.fnCalls) {
                        await fnC.run();
                      }
                      await UserStore.instance.saveMessage(chat, message);
                    },
                    child: Text('Run'))
            ],
          ),
        ),
      ),
    );
  }
}

class CodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    var language = '';

    if (element.attributes['class'] != null) {
      String lg = element.attributes['class'] as String;
      language = lg.substring(9);
    }
    return SizedBox(
      child: SelectableHighlightView(
        // The original code to be highlighted
        element.textContent,

        // Specify language
        // It is recommended to give it a value for performance
        language: language,

        // Specify highlight theme
        // All available themes are listed in `themes` folder
        theme: a11yLightTheme,

        // Specify padding
        padding: const EdgeInsets.all(8),

        // Specify text style
        textStyle: TextStyle(fontFamily: 'monospace', fontSize: 14.0),
      ),
    );
  }
}
