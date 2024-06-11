import 'dart:async';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import '../user_store.dart';
import 'input_tags.dart';

enum _SelectionType {
  none,
  word,
  // line,
}

class EntryPage extends StatefulWidget {
  final Map<String, Tag> tags;
  final Entry entry;
  const EntryPage(this.tags, this.entry);

  @override
  _EntryPageState createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  QuillController? _controller;
  final FocusNode _focusNode = FocusNode();
  Timer? _selectAllTimer;
  Timer? _saveTimer;
  _SelectionType _selectionType = _SelectionType.none;
  KeyboardVisibilityController keyboardVisibilityController =
      KeyboardVisibilityController();
  StreamSubscription<bool>? keyboardStream;

  @override
  void dispose() {
    _selectAllTimer?.cancel();
    _selectAllTimer = null;
    _saveTimer?.cancel();
    _saveTimer = null;
    _focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _saveEntry();
      _saveTimer?.cancel();
      _saveTimer = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    setState(() {
      _controller = QuillController(
        document: widget.entry.doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return Center(child: Text('Loading...'));
    }

    widget.entry.doc.changes.listen((event) => _startSaveTimer());
    return _buildWelcomeEditor(context);
  }

  bool _onTripleClickSelection() {
    final controller = _controller!;

    _selectAllTimer?.cancel();
    _selectAllTimer = null;

    // If you want to select all text after paragraph, uncomment this line
    // if (_selectionType == _SelectionType.line) {
    //   final selection = TextSelection(
    //     baseOffset: 0,
    //     extentOffset: controller.document.length,
    //   );

    //   controller.updateSelection(selection, ChangeSource.REMOTE);

    //   _selectionType = _SelectionType.none;

    //   return true;
    // }

    if (controller.selection.isCollapsed) {
      _selectionType = _SelectionType.none;
    }

    if (_selectionType == _SelectionType.none) {
      _selectionType = _SelectionType.word;
      _startTripleClickTimer();
      return false;
    }

    if (_selectionType == _SelectionType.word) {
      final child = controller.document.queryChild(
        controller.selection.baseOffset,
      );
      final offset = child.node?.documentOffset ?? 0;
      final length = child.node?.length ?? 0;

      final selection = TextSelection(
        baseOffset: offset,
        extentOffset: offset + length,
      );

      controller.updateSelection(selection, ChangeSource.remote);

      // _selectionType = _SelectionType.line;

      _selectionType = _SelectionType.none;

      _startTripleClickTimer();

      return true;
    }

    return false;
  }

  Future<void> _saveEntry() async {
    if (_controller?.document != null)
      await UserStore.instance
          .updateEntry(widget.entry.fromNewDoc(_controller!.document));
  }

  void _startSaveTimer() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 5), () async {
      await _saveEntry();
    });
  }

  void _startTripleClickTimer() {
    _selectAllTimer = Timer(const Duration(milliseconds: 900), () {
      _selectionType = _SelectionType.none;
    });
  }

  Widget _buildWelcomeEditor(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    final localizations = MaterialLocalizations.of(context);
    double screenWidth = MediaQuery.of(context).size.width;
    Widget quillEditor = QuillEditor(
      configurations: QuillEditorConfigurations(
        controller: _controller!,
        scrollable: true,
        autoFocus: false,
        //readOnly: false,
        placeholder: 'What is on your mind?',
        minHeight: screenHeight * .8,
        enableSelectionToolbar: true,
        contextMenuBuilder: (context, state) {
          var toolbar = QuillToolbar.simple(
            configurations: QuillSimpleToolbarConfigurations(
              controller: _controller!,
              // color: Theme.of(context).dialogBackgroundColor,
              multiRowsDisplay: false,
              showDividers: false,
              showColorButton: false,
              showSubscript: false,
              showSuperscript: false,
              showBackgroundColorButton: false,
              showFontFamily: false,
              showCodeBlock: false,
              showInlineCode: false,
              showClearFormat: false,
              showSearchButton: false,
              showLink: false,
              showFontSize: false,
              showQuote: false,
            ),
          );
          return Padding(
              padding: EdgeInsets.only(
                  top: defaultTargetPlatform == TargetPlatform.macOS ? 5 : 50),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [TextFieldTapRegion(child: toolbar)],
              ));
        },
        expands: false,
        padding: EdgeInsets.all(screenWidth > 400 ? 10 : 0),
        onTapUp: (details, p1) {
          return _onTripleClickSelection();
        },
        customStyles: DefaultStyles(
            placeHolder: DefaultTextBlockStyle(
                TextStyle(
                    fontSize: 16,
                    color: Colors.grey), // Your desired font size and color
                const VerticalSpacing(16, 0), // Adjust spacing as required
                const VerticalSpacing(0, 0), // Adjust spacing as required
                null),
            h1: DefaultTextBlockStyle(
                const TextStyle(
                  fontSize: 32,
                  color: Colors.black,
                  height: 1.15,
                  fontWeight: FontWeight.w300,
                ),
                const VerticalSpacing(16, 0),
                const VerticalSpacing(0, 0),
                null),
            sizeSmall: const TextStyle(fontSize: 9)),
      ),
      scrollController: ScrollController(),
      focusNode: _focusNode,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 50,
        centerTitle: false,
      ),
      body: Container(
          padding: EdgeInsets.only(top: 25, bottom: 25, left: 25, right: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(localizations.formatShortDate(widget.entry.date)),
                InkWell(
                    onTap: () async {
                      await UserStore.instance.deleteEntry(widget.entry);
                      Navigator.pop(context);
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 20,
                        ),
                        Text(
                          'Delete',
                          style: TextStyle(fontSize: 14),
                        )
                      ],
                    ))
              ]),
              Scrollbar(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: InputTags(widget.tags, widget.entry),
                ),
              ),
              quillEditor,
            ],
          )),
    );
  }
}
