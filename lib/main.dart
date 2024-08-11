import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nimbus/gemini.dart';
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
    if (defaultTargetPlatform == TargetPlatform.macOS) AppleProvider(),
    GoogleProvider(
        clientId: DefaultFirebaseOptions.currentPlatform.iosClientId!)
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
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        // used by Firebase SignInScreen
        // https://github.com/firebase/FirebaseUI-Flutter/blob/main/docs/firebase-ui-auth/theming.md
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: TextStyle(fontSize: 20.0),
            splashFactory: NoSplash.splashFactory,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20),
            backgroundColor: primary,
            foregroundColor: Colors.white,
          ),
        ),
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
          return _Login();
        }
        final user = snapshot.data;
        if (user != null) {
          UserStore(user.uid);
          _posthogFlutterPlugin.identify(userId: user.uid);
          user.getIdToken().then((jwt) {
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

class _Login extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      resizeToAvoidBottomInset: false,
      providers: [
        EmailAuthProvider(),
      ],
      sideBuilder: (context, constraints) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image.network(
            //   'logo.png',
            //   height: 60,
            //   width: 60,
            // ),
            const SizedBox(
              height: 30,
            ),
            const Text(
              'Nimbus',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            )
          ],
        );
      },
      footerBuilder: (context, action) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(
                height: 40,
              ),
              const Divider(
                // color: grey300,
                thickness: 0.7,
              ),
              const SizedBox(
                height: 40,
              ),
              AppleSignInButton(
                  auth: FirebaseAuth.instance,
                  loadingIndicator: Center(child: CircularProgressIndicator())),
              const SizedBox(
                height: 20,
              ),
              GoogleSignInButton(
                  loadingIndicator: Center(child: CircularProgressIndicator()),
                  auth: FirebaseAuth.instance,
                  clientId: DefaultFirebaseOptions.currentPlatform.iosClientId!)
            ],
          ),
        );
      },
      headerBuilder: (context, constraints, _) {
        return Center(
          child: Column(
            children: [
              const SizedBox(
                height: 80,
              ),
              // Image.network(
              //   'logo.png',
              //   height: 50,
              //   width: 50,
              // ),
            ],
          ),
        );
      },
    );
  }
}
