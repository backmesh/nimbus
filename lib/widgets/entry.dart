import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quill/extensions.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;

import 'tags_text_field.dart';
import '../entry_store.dart';

enum _SelectionType {
  none,
  word,
  // line,
}

class EntryPage extends StatefulWidget {
  final Entry entry;
  const EntryPage(this.entry);

  @override
  _EntryPageState createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  QuillController? _controller;
  final FocusNode _focusNode = FocusNode();
  Timer? _selectAllTimer;
  Timer? _saveTimer;
  _SelectionType _selectionType = _SelectionType.none;
  bool _hasSelection = false;

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
        onSelectionChanged: (textSelection) {
          setState(() {
            _hasSelection = !textSelection.isCollapsed;
          });
        },
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

      controller.updateSelection(selection, ChangeSource.REMOTE);

      // _selectionType = _SelectionType.line;

      _selectionType = _SelectionType.none;

      _startTripleClickTimer();

      return true;
    }

    return false;
  }

  void _saveEntry() {
    // async function but we are not waiting for it
    if (_controller?.document != null)
      EntryStore.instance
          .update(widget.entry.fromNewDoc(_controller!.document));
  }

  void _startSaveTimer() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 5), () {
      _saveEntry();
      _saveTimer?.cancel();
      _saveTimer = null;
    });
  }

  void _startTripleClickTimer() {
    _selectAllTimer = Timer(const Duration(milliseconds: 900), () {
      _selectionType = _SelectionType.none;
    });
  }

  Widget _buildWelcomeEditor(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final isToday = widget.entry.date.toString().substring(0, 10) ==
        DateTime.now().toString().substring(0, 10);
    final entryTitle =
        isToday ? 'Today' : localizations.formatShortDate(widget.entry.date);
    Widget quillEditor = QuillEditor(
      controller: _controller!,
      scrollController: ScrollController(),
      scrollable: true,
      focusNode: _focusNode,
      autoFocus: false,
      readOnly: false,
      placeholder: 'What is on your mind?',
      enableSelectionToolbar: isMobile(),
      expands: false,
      padding: EdgeInsets.all(10),
      onTapUp: (details, p1) {
        return _onTripleClickSelection();
      },
      customStyles: DefaultStyles(
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
    );
    var toolbar = QuillToolbar.basic(
      controller: _controller!,
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
      showIndent: false,
      showSearchButton: false,
      showLink: false,
      showFontSize: false,
      showRedo: false,
      showUndo: false,
      showListBullets: false,
      showListNumbers: false,
      showListCheck: false,
      showQuote: false,
      afterButtonPressed: _focusNode.requestFocus,
    );

    return Column(
      children: [
        Row(
          children: [
            Text(entryTitle),
            SizedBox(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TagsTextField(),
              ),
              width: 600,
            ),
            // IconButton.outlined(
            //   icon: Icon(Icons.add),
            //   onPressed: () async {},
            // ),
            if (!isToday)
              IconButton(
                icon: Icon(Icons.delete),
                color: Colors.red,
                onPressed: () async {
                  await EntryStore.instance.delete(widget.entry);
                },
              )
          ],
        ),
        AnimatedOpacity(
          opacity: _hasSelection ? 1.0 : 0.0,
          duration: Duration(milliseconds: 200),
          child: Visibility(
            visible: _hasSelection,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: toolbar,
          ),
        ),
        quillEditor,
      ],
    );
  }
}
