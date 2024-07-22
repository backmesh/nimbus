import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:dart_openai/dart_openai.dart';

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
                          await UserStore.instance.addMessage(
                              widget.chat, new Message(content: input));

                          // the system message that will be sent to the request.
                          final systemMessage =
                              OpenAIChatCompletionChoiceMessageModel(
                            content: [
                              OpenAIChatCompletionChoiceMessageContentItemModel
                                  .text(
                                "return any message you are given as JSON.",
                              ),
                            ],
                            role: OpenAIChatMessageRole.assistant,
                          );

                          // the user message that will be sent to the request.
                          final userMessage =
                              OpenAIChatCompletionChoiceMessageModel(
                            content: [
                              OpenAIChatCompletionChoiceMessageContentItemModel
                                  .text(
                                "Hello, I am a chatbot created by OpenAI. How are you today?",
                              ),
                            ],
                            role: OpenAIChatMessageRole.user,
                          );
                          // all messages to be sent.
                          final requestMessages = [
                            systemMessage,
                            userMessage,
                          ];
                          // the actual request.
                          OpenAIChatCompletionModel chatCompletion =
                              await OpenAI.instance.chat.create(
                            model: "gpt-3.5-turbo-1106",
                            responseFormat: {"type": "json_object"},
                            seed: 6,
                            messages: requestMessages,
                            temperature: 0.2,
                            maxTokens: 500,
                          );

                          print(chatCompletion.choices.first.message); // ...
                          print(chatCompletion.systemFingerprint); // ...
                          print(chatCompletion.usage.promptTokens); // ...
                          print(chatCompletion.id); // ...

                          setState(() {
                            input = "";
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
