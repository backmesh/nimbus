import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_generative_ai/src/model.dart'
    show createModelWithBaseUri;
import 'package:nimbus/user_store.dart';

// https://github.com/google-gemini/generative-ai-dart/tree/main/pkgs/google_generative_ai
// https://pub.dev/documentation/google_generative_ai/latest/google_generative_ai/google_generative_ai-library.html

final MODEL = 'gemini-1.5-flash';
final API_VERSION = 'v1beta';
final BASE_URL =
    'https://edge.backmesh.com/v1/proxy/PyHU4LvcdsQ4gm2xeniAFhMyuDl2/aUxjzrA9w7K9auXp6Be8';
// final BASE_URL =
//     'http://localhost:8787/v1/proxy/gbBbHCDBxqb8zwMk6dCio63jhOP2/lVXeOSrFwT9eQxtRRjp4';

class GeminiClient {
  late GenerativeModel client;

  static GeminiClient? _instance;

  GeminiClient._();

  static GeminiClient get instance {
    assert(_instance != null, 'Gemini must be initialized before accessing');
    return _instance!;
  }

  factory GeminiClient(String token) {
    _instance ??= GeminiClient._();
    Uri uri = Uri.parse('$BASE_URL/$API_VERSION');
    _instance!.client = createModelWithBaseUri(
      model: MODEL,
      apiKey: token,
      baseUri: uri,
    );
    return _instance!;
  }

  Stream<String> chatCompleteStream(
      List<Message> messages, Message last) async* {
    List<Content> contents = [];
    for (var msg in messages) {
      contents.add(await msg.toGemini());
    }
    final chat = client.startChat(history: contents);
    try {
      final lastMessage = await last.toGemini();
      await for (var response in chat.sendMessageStream(lastMessage)) {
        yield response.text!;
      }
    } catch (e) {
      print('Error: $e'); // Log any errors
      rethrow; // Re-throw the error after logging it
    }
  }
}
