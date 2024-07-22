import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:nimbus/widgets/common.dart';
import 'package:nimbus/widgets/entry_list.dart';

import '../user_store.dart';

class EntryPage extends StatefulWidget {
  final String entryKey;
  final Entry entry;
  const EntryPage(this.entryKey, this.entry);

  @override
  _EntryPageState createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

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
