import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_generative_ai/src/model.dart'
    show createModelWithBaseUri;
import 'package:nimbus/files.dart';
import 'package:nimbus/functions.dart';
import 'package:nimbus/logger.dart';
import 'package:nimbus/user_store.dart';

// https://github.com/google-gemini/generative-ai-dart/tree/main/pkgs/google_generative_ai
// https://pub.dev/documentation/google_generative_ai/latest/google_generative_ai/google_generative_ai-library.html

final MODEL = 'gemini-1.5-flash';
final API_VERSION = 'v1beta';
final BASE_URL =
    'https://edge.backmesh.com/v1/proxy/PyHU4LvcdsQ4gm2xeniAFhMyuDl2/aUxjzrA9w7K9auXp6Be8';
// final BASE_URL =
//     'http://localhost:8787/v1/proxy/gbBbHCDBxqb8zwMk6dCio63jhOP2/lVXeOSrFwT9eQxtRRjp4';
final sysMessage = """
You are a world-class programmer and system administrator that can complete any goal by executing code.
When you execute code, it will be executed **on the user's machine**. The user has given you **full and complete permission** to execute any code necessary to complete the task. Execute the code.
You can access the internet. Run **any code** to achieve the goal, and if at first you don't succeed, try again and again.
You can install new packages.
You can process and understand files with the following mimes: ${SUPPORTED_GEMINI_MIMES.join(', ')}.
The user can reference and upload files in their machine which is typically what they reference when they talk about filenames.
Write messages to the user in Markdown.
You are capable of **any** task.

User's OS: ${Platform.operatingSystem}
""";

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
        systemInstruction: Content.system(sysMessage),
        safetySettings: [
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.high)
        ],
        tools: [
          Tool(functionDeclarations: getGeminiFnDefs())
        ]);
    return _instance!;
  }

  Stream<Message> chatCompleteStream(
      List<Message> history, Message userMessage, Message aiMessage) async* {
    List<Content> contents = [Content.text(sysMessage)];
    for (var msg in history) {
      contents.add(await msg.toGemini());
    }
    final chat = client.startChat(history: contents);
    try {
      final lastMessage = await userMessage.toGemini();
      await for (var response in chat.sendMessageStream(lastMessage)) {
        aiMessage.content += response.text ?? '';
        List<FunctionCall> functionCalls = response.functionCalls.toList();
        if (functionCalls.isNotEmpty) {
          for (final functionCall in functionCalls)
            // TODO be able to cancel
            // TODO terminal user to respond with error
            aiMessage.fnCalls.add(FnCall(
                fnArgs: functionCall.args,
                fnName: functionCall.name,
                fnOutput: {}));
        }
        Logger.debug('Response: ${aiMessage.content}');
        yield aiMessage;
      }
    } catch (e) {
      Logger.debug('Error: $e'); // Log any errors
      rethrow; // Re-throw the error after logging it
    }
  }
}
