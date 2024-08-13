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
