import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/extensions.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:cloud_firestore/cloud_firestore.dart';

enum _SelectionType {
  none,
  word,
  // line,
}

class HomePage extends StatefulWidget {
  final String uid;
  const HomePage(this.uid);

  @override
  _HomePageState createState() => _HomePageState();
}

Document _deltaToDoc(String delta) {
  return Document.fromDelta(Delta.fromJson(jsonDecode(delta)));
}

String _docToDelta(Document doc) {
  return jsonEncode(doc.toDelta().toJson());
}

class Entry {
  Entry({required this.doc});

  Entry.fromDbCollection(Map<String, Object?> json)
      : this(
          doc: _deltaToDoc(json['delta']! as String),
        );

  final Document doc;

  Map<String, Object?> toDb() {
    return {
      'delta': _docToDelta(doc),
    };
  }
}

class EntryStore {
  static final CollectionReference _users =
      FirebaseFirestore.instance.collection('journalists');

  static CollectionReference<Entry> readAll(String uid) {
    return FirebaseFirestore.instance
        .collection('journalists/${uid}/entries')
        .withConverter<Entry>(
          fromFirestore: (snapshot, _) =>
              Entry.fromDbCollection(snapshot.data()!),
          toFirestore: (entry, _) => entry.toDb(),
        );
  }

  static write(String uid, DateTime date, Entry? entry) async {
    if (entry == null) return;
    if (entry.doc.isEmpty()) return;
    final val = entry.toDb();
    if (val['delta'] == '') return;
    await _users.doc(_entryKey(uid, date)).set(entry);
  }

  static Future<Entry?> read(String uid, DateTime date) async {
    final snapshot = _users.doc(_entryKey(uid, date));
    final entry = await snapshot.get();
    if (!entry.exists) return null;
    final delta = entry.get('delta');
    if (delta == null) return null;
    return Entry(doc: _deltaToDoc(delta));
  }

  static String _entryKey(String uid, DateTime date) {
    return '${uid}/entries/${date.toString().substring(0, 10)}';
  }
}

class _HomePageState extends State<HomePage> {
  QuillController? _controller;
  final FocusNode _focusNode = FocusNode();
  Timer? _selectAllTimer;
  _SelectionType _selectionType = _SelectionType.none;
  bool _hasSelection = false;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _selectAllTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _onNewDate(_date);
  }

  Future<void> _onNewDate(DateTime newDate) async {
    // save current entry if controller has been initiated
    if (_controller != null && _controller?.document != null) {
      await EntryStore.write(
          widget.uid, _date, Entry(doc: _controller?.document as Document));
    }
    try {
      final Entry? newEntry = await EntryStore.read(widget.uid, newDate);
      setState(() {
        _controller = QuillController(
          document: newEntry?.doc ?? Document(),
          selection: const TextSelection.collapsed(offset: 0),
          onSelectionChanged: (textSelection) {
            setState(() {
              _hasSelection = !textSelection.isCollapsed;
            });
          },
        );
        _date = newDate;
      });
    } catch (error) {
      print(error);
      setState(() {
        _controller = QuillController(
          document: Document(),
          selection: const TextSelection.collapsed(offset: 0),
          onSelectionChanged: (textSelection) {
            setState(() {
              _hasSelection = !textSelection.isCollapsed;
            });
          },
        );
        _date = newDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(body: Center(child: Text('Loading...')));
    }

    return Scaffold(
      body: _buildWelcomeEditor(context),
    );
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

  void _startTripleClickTimer() {
    _selectAllTimer = Timer(const Duration(milliseconds: 900), () {
      _selectionType = _SelectionType.none;
    });
  }

  bool _isTodaySelected() {
    return _date.toString().substring(0, 10) ==
        DateTime.now().toString().substring(0, 10);
  }

  Widget _buildWelcomeEditor(BuildContext context) {
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
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
      padding: EdgeInsets.zero,
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

    var dateText =
        _isTodaySelected() ? 'Today' : localizations.formatShortDate(_date);

    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(children: [
            Center(child: Text(dateText)),
            IconButton(
              icon: Icon(Icons.date_range),
              padding: EdgeInsets.zero,
              onPressed: () async {
                DateTime? newDate = await showDatePicker(
                    context: context,
                    initialEntryMode: DatePickerEntryMode.calendarOnly,
                    initialDate: _date,
                    firstDate: DateTime(2010),
                    lastDate: DateTime.now());
                if (newDate == null) return;
                await _onNewDate(newDate);
              },
            ),
          ]),
          Container(child: _hasSelection ? toolbar : Container()),
          Expanded(
            flex: 15,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: quillEditor,
            ),
          ),
        ],
      ),
    );
  }
}
