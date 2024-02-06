import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:journal/widgets/journal.dart';

import '../user_store.dart';

class HomePage extends StatefulWidget {
  final Map<String, Tag> tags;
  const HomePage(this.tags);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      // https://stackoverflow.com/questions/46551268/when-the-keyboard-appears-the-flutter-widgets-resize-how-to-prevent-this
      // we rely on padding instead so the size of the screen remains static and we can rely on it for our hacky formula
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white, // To make the AppBar transparent
        toolbarHeight: 40,
        actions: [
          PopupMenuButton<int>(
            icon: Icon(Icons.more_horiz),
            offset: Offset(0, 40),
            onSelected: (value) async {
              // Handle the menu item's value
              switch (value) {
                case 1:
                  await FirebaseUIAuth.signOut();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
              PopupMenuItem<int>(
                  value: 1,
                  child: InkWell(
                      onTap: () {
                        Navigator.pop(context, 1); // Closes the popup menu
                      },
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 18),
                          SizedBox(width: 10),
                          Text('Logout', style: TextStyle(fontSize: 14)),
                        ],
                      ))),
            ],
          ),
        ],
      ),
      body: JournalPage(widget.tags),
    );
  }
}
