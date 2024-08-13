import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:nimbus/user_store.dart';
import 'package:nimbus/widgets/chat.dart';
import 'package:nimbus/widgets/chat_list.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

Future<Object?> pushChatPage(BuildContext context, [Chat? chat]) {
  return Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChatPage(chat),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child; // No animation
        },
      ));
}

class CommonDrawer extends StatelessWidget {
  final Chat? chat;
  const CommonDrawer({required this.chat});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ChatListPage(chat: chat),
          ),
        ],
      ),
    );
  }
}

class CommonAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Chat? chat;
  const CommonAppBar({required this.chat});

  @override
  _CommonAppBarState createState() => _CommonAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(50);
}

class _CommonAppBarState extends State<CommonAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 50,
      automaticallyImplyLeading: false, // Remove the back button
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 1.0,
      scrolledUnderElevation: 2.0,
      shadowColor: Colors.grey,
      leading: IconButton(
        icon: Icon(Icons.menu),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
      titleSpacing: 10,
      title: FocusScope(
        canRequestFocus: false,
        child: DropdownButton<String>(
          value: UserStore.instance.model,
          items: UserStore.getModelOptions()
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                '   $value   ',
                style: TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) async {
            if (newValue != null) {
              await UserStore.instance.setModel(newValue);
              setState(() {});
            }
          },
          icon: Icon(Icons.arrow_drop_down),
          underline: SizedBox(),
          focusColor: Theme.of(context).appBarTheme.backgroundColor,
          dropdownColor: Theme.of(context)
              .appBarTheme
              .backgroundColor, // Match AppBar color
        ),
      ),
      actions: [
        IconButton(
            onPressed: widget.chat != null ? () => pushChatPage(context) : null,
            icon: Icon(Icons.add_comment)),
        IconButton(
            onPressed: widget.chat != null
                ? () async {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Delete Chat'),
                          content: const Text('''This cannot be undone.'''),
                          actions: [
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text(
                                'Delete',
                              ),
                              onPressed: () async {
                                await UserStore.instance
                                    .deleteChat(widget.chat!);
                                Navigator.of(context).pop();
                                pushChatPage(context);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                : null,
            icon: Icon(Icons.delete)),
        PopupMenuButton<int>(
          icon: Icon(Icons.more_horiz),
          offset: Offset(0, 40),
          onSelected: (value) async {
            // Handle the menu item's value
            switch (value) {
              case 1:
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Logout'),
                      content: const Text(
                          '''If you Logout, you will need to log in to access your account again.'''),
                      actions: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text(
                            'Logout',
                          ),
                          onPressed: () async {
                            await FirebaseUIAuth.signOut();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
                await Posthog().capture(eventName: 'Logout');
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
            PopupMenuItem<int>(
                value: 1,
                child: InkWell(
                    onTap: () {
                      Navigator.pop(context, 1);
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
    );
  }
}
