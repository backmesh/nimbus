import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  late final focusNode = FocusNode(
    onKey: _handleKeyPress,
  );

  KeyEventResult _handleKeyPress(FocusNode focusNode, RawKeyEvent event) {
    // handles submit on enter
    if (event.isKeyPressed(LogicalKeyboardKey.enter) && !event.isShiftPressed) {
      sendMessage();
      // handled means that the event will not propagate
      return KeyEventResult.handled;
    }
    // ignore every other keyboard event including SHIFT+ENTER
    return KeyEventResult.ignored;
  }

  Files filesObj = new Files();
  List<String> files = [];
  List<String> selectedFiles = [];

  Future<void> setFilesInHomeDirectory() async {
    files = await Files.getSupportedFilePaths();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
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
    if (richTextController.text.trim().replaceAll('\n', '').isNotEmpty) {
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
          optionsBuilder: (TextEditingValue textEditingValue) async {
            // print('optionsBuilder called with: ${textEditingValue.text}');
            if (textEditingValue.text.contains('@')) {
              // lazily load files to ask for permissions when it makes sense
              if (files.length == 0) await setFilesInHomeDirectory();
              String query = textEditingValue.text.split('@').last;
              List<String> filteredFiles = files
                  .where((file) =>
                      file.contains(query) && !selectedFiles.contains(file))
                  .toList();
              // print('Filtered files: $filteredFiles');
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
            final borderColor = Colors.grey.withOpacity(0.5);
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
              style: TextStyle(fontSize: 14.0),
              maxLines: null,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: borderColor),
                ),
                filled: true,
                fillColor: Colors.white,
                hoverColor: Colors.white,
                suffixIcon: AnimatedOpacity(
                  opacity: input.isNotEmpty ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 100),
                  child: IconButton(
                    icon: Icon(Icons.send),
                    padding: EdgeInsets.only(left: 5),
                    onPressed: input.trim().replaceAll('\n', '').isNotEmpty
                        ? () => sendMessage()
                        : null,
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
                          title: Text(
                            option,
                            style: TextStyle(fontSize: 14),
                          ),
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
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              fontSize: 14),
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
