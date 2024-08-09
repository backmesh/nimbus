import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_generative_ai/src/model.dart'
    show createModelWithBaseUri;
import 'package:nimbus/user_store.dart';

final MODEL = 'gemini-1.5-flash-latest';
final API_VERSION = 'v1beta';
final BASE_URL =
    'edge.backmesh.com/v1/proxy/PyHU4LvcdsQ4gm2xeniAFhMyuDl2/aUxjzrA9w7K9auXp6Be8';

//
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
    _instance!.client = createModelWithBaseUri(
        model: MODEL, apiKey: token, baseUri: Uri.https(BASE_URL, API_VERSION));
    return _instance!;
  }

  Future<Message> chatComplete(List<Message> messages, Message last) async {
    List<Content> contents = messages.map((msg) => msg.toGemini()).toList();
    final chat = client.startChat(history: contents);
    final response = await chat.sendMessage(
      last.toGemini(),
    );
    return new Message(content: response.text ?? '', model: MODEL);
  }
}
