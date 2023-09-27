import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:journal/firebase_options.dart';

import 'dart:io' show Platform;

import 'pages/home_page.dart';

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
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Journal',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
      ],
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      supportedLocales: [
        const Locale('en', 'US'),
      ],
      home: SignInScreen(
        showAuthActionSwitch: false,
        actions: [
          AuthStateChangeAction<AuthFailed>((context, state) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return ErrorText(exception: state.exception);
              }),
            );
          }),
          // TODO dry up
          AuthStateChangeAction<SignedIn>((context, state) {
            final uid = state.user?.uid;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                if (uid == null) Text(state.toString());
                return HomePage(uid as String);
              }),
            );
          }),
          AuthStateChangeAction<UserCreated>((context, state) {
            final uid = state.credential.user?.uid;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                if (uid == null) Text(state.toString());
                return HomePage(uid as String);
              }),
            );
          }),
        ],
      ),
    );
  }
}
