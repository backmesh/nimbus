import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:nimbus/widgets/common.dart';

import '../user_store.dart';

class ChatPage extends StatefulWidget {
  final String entryKey;
  final Entry entry;
  const ChatPage(this.entryKey, this.entry);

  @override
  _EntryPageState createState() => _EntryPageState();
}

class _EntryPageState extends State<ChatPage> {
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
              right: 25),
          child: Column(
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(widget.entryKey)],
          ),
        ));
  }
}
