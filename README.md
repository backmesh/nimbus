# nimbus

Superpower your desktop with an LLM that can complete tasks for you

# architecture

- Flutter app for desktops that lets us target MacOS and Linux with a single codebase
- Firebase Firestore to preserve chats and messages with security rules to ensure only authenticated users can read or write their data.
- Firebase Authentication to let users log in using email or Google.
- There is no backend. We use a pass-through server proxy to directly call the Google AI Gemini API.
- Firebase Hosting for the landing page

# next

- [ ] Firebase App Check to increase security
- [ ] Use Firebase Storage when files exceed the size limit for direct upload to Google AI Gemini API
