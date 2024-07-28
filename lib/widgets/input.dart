import 'package:flutter/material.dart';

import '../user_store.dart';

class InputField extends StatefulWidget {
  final List<Message> messages;
  final Function(List<Message>, String) onSendMessage;
  const InputField(this.onSendMessage, this.messages);

  @override
  _InputFieldState createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  String input = "";
  final TextEditingController _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void sendMessage() async {
    if (input.isNotEmpty) {
      widget.onSendMessage(widget.messages, input);
      input = "";
      _inputController.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
        controller: _inputController,
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
        // Fires on enter keypress
        onSubmitted: (text) => sendMessage(),
        decoration: InputDecoration(
            hintText: 'Type your message...',
            border: InputBorder.none, // Remove the underline
            suffixIcon: IconButton(
                icon: Icon(Icons.send),
                onPressed: input.isNotEmpty ? () => sendMessage() : null)));
  }
}
