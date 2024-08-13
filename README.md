# nimbus

Nimbus gives Google's Gemini LLM access to your desktop so it can easily read files and run code for you.

# architecture

- Flutter desktop app that targets MacOS and Linux with a single codebase.
- Firebase Firestore is used to preserve chats and messages with security rules to ensure that only authenticated users can read or write their data.
- Firebase Authentication is used to let users log in using email or Google.
- There is no backend. The Flutter client uses a pass-through server proxy to directly call the Google AI Gemini API.
- Firebase Hosting for the landing page

# next

- [ ] Firebase App Check to increase security
- [ ] Use Firebase Storage when files exceed the size limit for direct upload to Google AI Gemini API

# macos app release

1. Build, sign and notarize app in Xcode. Select `Product > Archive` => `Distribute App` => `Direct Distribution` and verify it

```bash
spctl -a -vvv -t install Nimbus.app
```

2. Zip it and upload it to GCP

https://console.cloud.google.com/storage/browser/nimbus-d5268.appspot.com

## macos dmg release

We needed a Developer ID Installer certificate added to our identity via Xcode > Preferences > Accounts

1. Create DMG from App

https://github.com/sindresorhus/create-dmg

```bash
create-dmg path/to/Nimbus.app
```

Verify it

```bash
spctl -a -vvv -t install Nimbus\ 1.0.1.dmg
```

2. Notarize and staple DMG with Apple's `notarytool`

https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow#3087734

https://wiki.lazarus.freepascal.org/Notarization_for_macOS_10.14.5%2B

```bash
xcrun notarytool submit Nimbus\ 1.0.1.dmg --keychain-profile "notarytool-password" --wait
xcrun notarytool history --keychain-profile "notarytool-password"
xcrun stapler staple Nimbus\ 1.0.1.dmg
```

Verify it

```bash
spctl -a -vvv -t install Nimbus.app
spctl -a -vvv -t install Nimbus\ 1.0.1.dmg
```

3. Zip it and upload it to GCP

https://console.cloud.google.com/storage/browser/nimbus-d5268.appspot.com
