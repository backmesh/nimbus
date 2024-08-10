import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nimbus/gemini.dart';
import 'package:nimbus/open_ai.dart';
import 'package:nimbus/user_store.dart';
import 'package:nimbus/firebase_options.dart';
import 'package:nimbus/widgets/chat.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
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
      home: _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  final _posthogFlutterPlugin = Posthog();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ContinueWithApple();
        }
        final user = snapshot.data;
        if (user != null) {
          UserStore(user.uid);
          _posthogFlutterPlugin.identify(userId: user.uid);
          user.getIdToken().then((jwt) {
            OpenAIClient(jwt!);
            GeminiClient(jwt!);
          });
        }

        if (user != null && !user.emailVerified) {
          final emailProvider = user.providerData
              .any((provider) => provider.providerId == 'password');
          if (emailProvider) {
            user.sendEmailVerification().then((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Verification email sent to ${user.email}. Please verify your email.'),
                ),
              );
              FirebaseAuth.instance.signOut();
            });
          }
        }

        return ChatPage();
      },
    );
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
