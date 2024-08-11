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
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ChatListPage(),
          ),
        ],
      ),
    );
  }
}

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Chat? chat;
  const CommonAppBar({required this.chat});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 50,
      automaticallyImplyLeading: false, // Remove the back button
      leading: IconButton(
        icon: Icon(Icons.menu),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
      actions: [
        IconButton(
            onPressed: chat != null ? () => pushChatPage(context) : null,
            icon: Icon(Icons.add_comment)),
        IconButton(
            onPressed: chat != null
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
                                await UserStore.instance.deleteChat(chat!);
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
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(50);
}
