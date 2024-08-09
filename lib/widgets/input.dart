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
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void sendMessage() async {
    if (input.isNotEmpty) {
      widget.onSendMessage(widget.messages, input);
      input = "";
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building InputField widget');
    print(widget.files);
    late TextEditingController textEditingController;
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
            int atIndex = input.lastIndexOf('@');
            String newText = input.substring(0, atIndex + 1) + selection;
            print('newText: $newText');
            input = newText;
            textEditingController.text = newText;
            // Update the TextEditingController
            // setState(() {});
          },
          fieldViewBuilder: (BuildContext context,
              TextEditingController fieldTextEditingController,
              FocusNode focusNode,
              VoidCallback onFieldSubmitted) {
            textEditingController = fieldTextEditingController;
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
          optionsViewOpenDirection: OptionsViewOpenDirection.up,
          optionsViewBuilder: (BuildContext context,
              AutocompleteOnSelected<String> onSelected,
              Iterable<String> options) {
            print('optionsViewBuilder called with options: $options');
            return Align(
              alignment: Alignment.bottomLeft,
              child: Material(
                elevation: 4.0, // Add elevation to make it more visible
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: options.length * 50.0,
                  constraints: BoxConstraints(maxHeight: 200), // Limit height
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
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
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
