import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:nimbus/user_store.dart';
import 'package:nimbus/widgets/chat.dart';
import 'package:nimbus/widgets/chat_list.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

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
            onPressed: () async {
              final chat = new Chat();
              Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        ChatPage(chat),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return child; // No animation
                    },
                  ));
              await UserStore.instance.saveChat(chat);
            },
            icon: Icon(Icons.add_comment)),
        PopupMenuButton<int>(
          icon: Icon(Icons.more_horiz),
          offset: Offset(0, 40),
          onSelected: (value) async {
            // Handle the menu item's value
            switch (value) {
              case 1:
                await FirebaseUIAuth.signOut();
                // TODO show modal like nutripic
                await Posthog().capture(eventName: 'Logout');
                break;
              case 2:
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    Posthog().capture(eventName: 'DeleteAccountModal');
                    return AlertDialog(
                      title: const Text('Delete your account?'),
                      content: const Text(
                          '''If you select Delete we will delete your account permanently.

Your app data will also be deleted and you won't be able to retrieve it.'''),
                      actions: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                            Posthog().capture(eventName: 'DeleteAccountCancel');
                          },
                        ),
                        TextButton(
                          child: const Text(
                            'Delete',
                            selectionColor: Colors.red,
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () async {
                            try {
                              await Posthog()
                                  .capture(eventName: 'DeleteAccountConfirm');
                              User? user = FirebaseAuth.instance.currentUser;
                              await user?.delete();
                            } catch (e) {
                              // TODO Handle exceptions
                            }
                            // Call the delete account function
                          },
                        ),
                      ],
                    );
                  },
                );
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
            PopupMenuItem<int>(
                value: 2,
                child: InkWell(
                    onTap: () {
                      Navigator.pop(context, 2); // Closes the popup menu
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outlined,
                          size: 18,
                          color: Colors.red,
                        ),
                        SizedBox(width: 10),
                        Text('Delete Account',
                            style: TextStyle(fontSize: 14, color: Colors.red)),
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
