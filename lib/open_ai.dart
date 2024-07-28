import 'package:dart_openai/dart_openai.dart';
import 'package:nimbus/user_store.dart';

final model = "gpt-3.5-turbo-1106";

class OpenAIClient {
  static OpenAIClient? _instance;

  OpenAIClient._();

  static OpenAIClient get instance {
    assert(_instance != null, 'OpenAI must be initialized before accessing');
    return _instance!;
  }

  factory OpenAIClient(String token) {
    OpenAI.baseUrl =
        "https://nimbusopenaiproxy.luis-fernando.workers.dev/"; // "https://api.openai.com/v1"; // the default one.
    OpenAI.apiKey = token;
    _instance ??= OpenAIClient._();
    return _instance!;
  }

  Future<Message> chatComplete(List<Message> messages) async {
    OpenAIChatCompletionModel chatCompletion =
        await OpenAI.instance.chat.create(
      model: model,
      // responseFormat: {"type": "json_object"},
      seed: 6,
      messages: messages.map((msg) => msg.toOpenAI()).toList(),
      temperature: 0.2,
      maxTokens: 500,
    );
    final stream = OpenAI.instance.chat.createStream(
      model: model,
      // responseFormat: {"type": "json_object"},
      seed: 6,
      messages: messages.map((msg) => msg.toOpenAI()).toList(),
      temperature: 0.2,
      maxTokens: 500,
    );
    await for (var completion in stream) {
      print(completion);
      print(completion.choices.first.delta.content?.first?.text ?? '');
    }
    return new Message(
        content: chatCompletion.choices.first.message.content?.first.text ?? '',
        model: model);
  }
}
