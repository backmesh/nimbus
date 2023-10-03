import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:journal/user_store.dart';
import 'package:journal/firebase_options.dart';

import 'widgets/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  if (Platform.isMacOS || Platform.isIOS) {
    FirebaseUIAuth.configureProviders([
      AppleProvider(),
    ]);
  }
  runApp(Main());
}

class Main extends StatefulWidget {
  // This widget is the root of your application.

  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> {
  late StreamSubscription<User?> userStream;
  User? user = FirebaseAuth.instance.currentUser;

  void initState() {
    super.initState();
    userStream = FirebaseAuth.instance.authStateChanges().listen((fbUser) {
      if (fbUser == null) return;
      setState(() {
        user = fbUser;
      });
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    if (user != null) UserStore(user!.uid);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Journal',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      supportedLocales: [
        const Locale('en', 'US'),
      ],
      home: user != null
          ? StreamBuilder<QuerySnapshot<Tag>>(
              stream: UserStore.instance.tagsRef.snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot<Tag>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    !snapshot.hasData) {
                  return Center(
                      child:
                          CircularProgressIndicator()); // Show a loading indicator while waiting
                }
                if (snapshot.hasError) {
                  return Text(snapshot.error
                      .toString()); // Show error or a placeholder when no data
                }
                final docs = snapshot.data!.docs;
                Map<String, Tag> tags = {
                  for (var doc in docs) doc.id: doc.data()
                };
                return HomePage(tags);
              })
          : SignInScreen(
              showAuthActionSwitch: false,
            ),
    );
  }
}
