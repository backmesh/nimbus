import 'package:flutter/material.dart';
import 'package:nimbus/files.dart';

import '../user_store.dart';

class InputField extends StatefulWidget {
  final List<Message> messages;
  final Future<void> Function(List<Message>, Message) onSendMessage;
  const InputField(this.onSendMessage, this.messages);

  @override
  _InputFieldState createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  String input = '';
  final richTextController = RichTextEditingController();
  final focusNode = FocusNode();
  List<String> files = [];
  List<String> selectedFiles = [];

  Future<void> setFilesInHomeDirectory() async {
    files = await Files.getSupportedFilePaths();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    setFilesInHomeDirectory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(focusNode);
    });
  }

  @override
  void dispose() {
    richTextController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void sendMessage() async {
    if (richTextController.text.isNotEmpty) {
      await widget.onSendMessage(
          widget.messages,
          new Message(
              content: richTextController.text,
              // Pass a copy
              filePaths: List<String>.from(richTextController.selectedFiles)));
      richTextController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    // print('Building InputField widget');
    return Column(
      children: [
        RawAutocomplete<String>(
          textEditingController: richTextController,
          focusNode: focusNode,
          optionsBuilder: (TextEditingValue textEditingValue) {
            // print('optionsBuilder called with: ${textEditingValue.text}');
            if (textEditingValue.text.contains('@')) {
              String query = textEditingValue.text.split('@').last;
              List<String> filteredFiles = files
                  .where((file) =>
                      file.contains(query) && !selectedFiles.contains(file))
                  .toList();
              print('Filtered files: $filteredFiles');
              return filteredFiles;
            }
            return const Iterable<String>.empty();
          },
          onSelected: (String selection) {
            // print('onSelected called with: $selection');
            int atIndex = input.lastIndexOf('@');
            String newText = input.substring(0, atIndex + 1) + selection;
            // print('newText: $newText');
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
                // print('TextField onChanged called with: $text');
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
                suffixIcon: AnimatedOpacity(
                  opacity: input.isNotEmpty ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 100),
                  child: IconButton(
                    icon: Icon(Icons.send),
                    onPressed: input.isNotEmpty ? () => sendMessage() : null,
                  ),
                ),
              ),
            );
          },
          optionsViewOpenDirection: OptionsViewOpenDirection.up,
          optionsViewBuilder: (BuildContext context,
              AutocompleteOnSelected<String> onSelected,
              Iterable<String> options) {
            // print('optionsViewBuilder called with options: $options');
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
                      // print('Building option: $option');
                      return GestureDetector(
                        onTap: () {
                          // print('Option tapped: $option');
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
    this.text = text;
  }

  @override
  void clear() {
    super.clear();
    selectedFiles.clear();
  }

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    final textSpans = <TextSpan>[];
    int start = 0;

    for (final file in selectedFiles) {
      final index = text.indexOf('@$file', start); // Include '@' in the search
      if (index != -1) {
        if (index > start) {
          textSpans.add(TextSpan(text: text.substring(start, index)));
        }
        textSpans.add(TextSpan(
          text: '@$file', // Include '@' in the highlighted text
          style: TextStyle(
            backgroundColor: Colors.yellow, // Highlight @ and selected files
          ),
        ));
        start = index + file.length + 1; // Adjust start position to include @
      }
    }

    if (start < text.length) {
      textSpans.add(TextSpan(text: text.substring(start)));
    }

    return TextSpan(style: style, children: textSpans);
  }
}
