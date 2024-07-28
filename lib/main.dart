import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kDebugMode;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nimbus/openai.dart';
import 'package:nimbus/user_store.dart';
import 'package:nimbus/firebase_options.dart';
import 'package:nimbus/widgets/chat.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (false) {
    try {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      FirebaseFirestore.instance.settings = Settings(
        sslEnabled: false,
        persistenceEnabled: false,
      );
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
    } catch (e) {
      print(e);
    }
  } else {
    FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
  FirebaseUIAuth.configureProviders([
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS)
      AppleProvider()
  ]);
  runApp(Main());
}

class Main extends StatefulWidget {
  // This widget is the root of your application.

  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> with WidgetsBindingObserver {
  late StreamSubscription<User?> userStream;
  User? user = null;
  final _posthogFlutterPlugin = Posthog();

  Future<void> init(User? fbUser) async {
    if (fbUser != null) {
      _posthogFlutterPlugin.identify(userId: fbUser.uid);
      final token = await fbUser.getIdToken();
      OpenAIClient(token!);
      UserStore(fbUser.uid);
    } else {
      UserStore.clear();
    }
    setState(() {
      user = fbUser;
    });
  }

  void initState() {
    super.initState();
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser != null) init(fbUser);
    userStream = FirebaseAuth.instance.authStateChanges().listen(init);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    userStream.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    const primary = Color.fromRGBO(23, 89, 115, 1);
    //const secondary = Color.fromRGBO(140, 184, 159, 1);
    return MaterialApp(
        navigatorObservers: [
          // The PosthogObserver records screen views automatically
          PosthogObserver()
        ],
        debugShowCheckedModeBanner: false,
        title: 'Nimbus',
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
        ],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: primary),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        supportedLocales: [
          const Locale('en', 'US'),
        ],
        home: user == null ? ContinueWithApple() : ChatPage(new Chat()));
  }
}

class ContinueWithApple extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      showAuthActionSwitch: false,
    );
  }
}
