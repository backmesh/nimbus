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
  String input = '';
  final richTextController = RichTextEditingController();
  final focusNode = FocusNode();
  List<String> selectedFiles = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    richTextController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void sendMessage() async {
    if (richTextController.text.isNotEmpty) {
      widget.onSendMessage(widget.messages, richTextController.text);
      richTextController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building InputField widget');
    return Column(
      children: [
        RawAutocomplete<String>(
          textEditingController: richTextController,
          focusNode: focusNode,
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
            selectedFiles.add(selection);
            richTextController.updateText(newText, selectedFiles);
            // setState(() {});
          },
          fieldViewBuilder: (BuildContext context,
              TextEditingController fieldTextEditingController,
              FocusNode focusNode,
              VoidCallback onFieldSubmitted) {
            return TextField(
              controller: fieldTextEditingController,
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

class RichTextEditingController extends TextEditingController {
  List<String> selectedFiles = [];

  void updateText(String text, List<String> selectedFiles) {
    this.selectedFiles = selectedFiles;
    value = value.copyWith(
      text: text,
      selection: TextSelection.fromPosition(
        TextPosition(offset: text.length),
      ),
      composing: TextRange.empty,
    );
  }

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    final textSpans = <TextSpan>[];
    int start = 0;

    for (final file in selectedFiles) {
      final index = text.indexOf(file, start);
      if (index != -1) {
        if (index > start) {
          textSpans.add(TextSpan(text: text.substring(start, index)));
        }
        textSpans.add(TextSpan(
          text: file,
          style: TextStyle(
            backgroundColor: Colors.yellow, // Highlight @ and selected files
          ),
        ));
        start = index + file.length;
      }
    }

    if (start < text.length) {
      textSpans.add(TextSpan(text: text.substring(start)));
    }

    return TextSpan(style: style, children: textSpans);
  }
}
