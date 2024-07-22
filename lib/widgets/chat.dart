import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:nimbus/widgets/common.dart';

import '../user_store.dart';

class ChatPage extends StatefulWidget {
  final String chatKey;
  final Chat chat;
  const ChatPage(this.chatKey, this.chat);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<String> messages = []; // List to hold chat messages
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CommonAppBar(),
      drawer: CommonDrawer(),
      body: Container(
        padding: EdgeInsets.only(
          top: defaultTargetPlatform == TargetPlatform.iOS ? 100 : 75,
          bottom: 25,
          left: 25,
          right: 25,
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading:
                        Icon(Icons.message, size: 20), // Make the icon smaller
                    title: Padding(
                      padding: const EdgeInsets.only(
                          left: 8.0), // Add space between icon and title
                      child: Text(messages[index]), // Display each message
                    ),
                  );
                },
              ),
            ),
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
                        onPressed: () {
                          setState(() {
                            messages
                                .add(_controller.text); // Add message to list
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
