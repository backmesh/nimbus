# app

demo app

# submission

bump version in pubspec.yaml

## ios submission

- `flutter build ipa --release`
- Submit on Transporter

## macos submission

https://docs.flutter.dev/deployment/macos#create-a-build-archive-with-xcode

- `flutter build macos`
- Open Xcode and select `Product > Archive` to open the archive created in the previous step.
- Click the `Validate App` button
- After the archive has been successfully validated, click `Distribute App`

## local firebase

https://firebase.google.com/codelabs/get-started-firebase-emulators-and-flutter#3

```bash
firebase emulators:start
```
