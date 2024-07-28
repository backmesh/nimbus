import 'dart:async';

import 'package:dart_openai/dart_openai.dart';
import 'package:nimbus/user_store.dart';

final model = "gpt-4o";

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
    // final chatStream = OpenAI.instance.chat.createStream(
    //     model: model,
    //     seed: 423,
    //     n: 2,
    //     messages: messages.map((msg) => msg.toOpenAI()).toList());
    // chatStream.listen(
    //   (streamChatCompletion) {
    //     print("Received streamChatCompletion: $streamChatCompletion");
    //     final content = streamChatCompletion.choices.first.delta.content;
    //     if (content != null) {
    //       print("content $content");
    //     } else {
    //       print("No content received in this streamChatCompletion.");
    //     }
    //   },
    //   onDone: () {
    //     print("Done");
    //   },
    //   onError: (error) {
    //     print("Error: $error");
    //   },
    // );

    OpenAIChatCompletionModel chatCompletion =
        await OpenAI.instance.chat.create(
      model: model,
      // responseFormat: {"type": "json_object"},
      seed: 6,
      messages: messages.map((msg) => msg.toOpenAI()).toList(),
      temperature: 0.2,
      maxTokens: 500,
    );

    return new Message(
        content: chatCompletion.choices.first.message.content?.first.text ?? '',
        model: model);
  }
}
