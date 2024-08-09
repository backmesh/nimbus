import 'package:flutter/material.dart';

import '../user_store.dart';

class InputField extends StatefulWidget {
  final List<Message> messages;
  final Function(List<Message>, String) onSendMessage;
  final List<String> files; // Add a list of files
  const InputField(this.onSendMessage, this.messages, this.files);

  @override
  _InputFieldState createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  String input = "";
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
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
    print('Building InputField widget');
    print(widget.files);
    return Column(
      children: [
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            print('optionsBuilder called with: ${textEditingValue.text}');
            if (textEditingValue.text.contains('@')) {
              String query = textEditingValue.text.split('@').last;
              List<String> filteredFiles =
                  widget.files.where((file) => file.contains(query)).toList();
              print('Filtered files: $filteredFiles');
              return filteredFiles;
            }
            return const Iterable<String>.empty();
          },
          onSelected: (String selection) {
            print('onSelected called with: $selection');
            String currentText = _inputController.text;
            int atIndex = currentText.lastIndexOf('@');
            String newText = currentText.substring(0, atIndex + 1) + selection;
            _inputController.text = newText;
            _inputController.selection = TextSelection.fromPosition(
              TextPosition(offset: newText.length),
            );
            setState(() {
              input = newText;
            });
          },
          fieldViewBuilder: (BuildContext context,
              TextEditingController textEditingController,
              FocusNode focusNode,
              VoidCallback onFieldSubmitted) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              onChanged: (text) {
                print('TextField onChanged called with: $text');
                if (text.isNotEmpty && input.isEmpty ||
                    text.isEmpty && input.isNotEmpty) {
                  input = text;
                  setState(() {});
                } else {
                  input = text;
                }
              },
              onSubmitted: (text) {
                sendMessage();
                onFieldSubmitted(); // Call the onFieldSubmitted callback
              },
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: input.isNotEmpty ? () => sendMessage() : null,
                ),
              ),
            );
          },
          optionsMaxHeight: 1,
          optionsViewOpenDirection: OptionsViewOpenDirection.up,
          optionsViewBuilder: (BuildContext context,
              AutocompleteOnSelected<String> onSelected,
              Iterable<String> options) {
            print('optionsViewBuilder called with options: $options');
            return Material(
              elevation: 4.0, // Add elevation to make it more visible
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  print('Building option: $option'); // Debug print
                  return GestureDetector(
                    onTap: () {
                      print('Option tapped: $option'); // Debug print
                      onSelected(option);
                    },
                    child: ListTile(
                      title: Text(option),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
