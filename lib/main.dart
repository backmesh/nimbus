import 'dart:async';

import 'package:dart_openai/dart_openai.dart';
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
import 'package:nimbus/user_store.dart';
import 'package:nimbus/firebase_options.dart';
import 'package:nimbus/widgets/common.dart';
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
  User? user = FirebaseAuth.instance.currentUser;
  final _posthogFlutterPlugin = Posthog();

  void initState() {
    super.initState();
    if (user != null) UserStore(user!.uid);
    userStream =
        FirebaseAuth.instance.authStateChanges().listen((fbUser) async {
      if (fbUser != null) {
        _posthogFlutterPlugin.identify(userId: fbUser.uid);
        OpenAI.baseUrl =
            "https://nimbusopenaiproxy.luis-fernando.workers.dev/"; // "https://api.openai.com/v1"; // the default one.
        final token = await fbUser.getIdToken();
        OpenAI.apiKey = token!;
        UserStore(fbUser.uid);
      } else {
        UserStore.clear();
      }
      setState(() {
        user = fbUser;
      });
    });
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
        home: user == null ? ContinueWithApple() : HomePage());
  }
}

class ContinueWithApple extends StatelessWidget {
  // TODO modify to say continue instead of sign in
  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      showAuthActionSwitch: false,
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CommonAppBar(),
      drawer: CommonDrawer(),
    );
  }
}
