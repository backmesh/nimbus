import 'package:process_run/process_run.dart';
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
  late Future<FunctionResponse> Function(FunctionCall) dispatchFunctionCall;

  static GeminiClient? _instance;

  GeminiClient._();

  static GeminiClient get instance {
    assert(_instance != null, 'Gemini must be initialized before accessing');
    return _instance!;
  }

  factory GeminiClient(String token) {
    _instance ??= GeminiClient._();

    Future<Map<String, Object?>> runShellCommand(
        Map<String, Object?> args) async {
      final command = args['command'] as String;
      final arguments =
          (args['arguments'] as List<dynamic>? ?? []).cast<String>();
      final results = await run(command + arguments.join(' '));
      for (var result in results) {
        if (result.exitCode == 0) {
          print('Command output: ${result.stdout}');
          return {'output': result.stdout.trim()};
        } else {
          print('Error running command: ${result.stderr}');
          return {'error': result.stderr.trim()};
        }
      }
      // Add this return statement to handle cases where no result is returned
      return {'error': 'No result returned from shell command'};
    }

    final runShellCommandFunction = FunctionDeclaration(
        'runShellCommand',
        'Run a shell command and set computer settings.',
        Schema.object(properties: {
          'command': Schema.string(
              description: 'The shell command to run.', nullable: false),
          'arguments': Schema.array(
              items: Schema.string(),
              description: 'Arguments for the shell command.',
              nullable: false)
        }));
    final functions = {runShellCommandFunction.name: runShellCommand};
    _instance!.dispatchFunctionCall = (FunctionCall call) async {
      final function = functions[call.name]!;
      final result = await function(call.args);
      return FunctionResponse(call.name, result);
    };

    Uri uri = Uri.parse('$BASE_URL/$API_VERSION');
    _instance!.client = createModelWithBaseUri(
        model: MODEL,
        apiKey: token,
        baseUri: uri,
        tools: [
          Tool(functionDeclarations: [runShellCommandFunction])
        ]);
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
        String message = response.text ?? '';
        List<FunctionCall> functionCalls = response.functionCalls.toList();
        if (functionCalls.isNotEmpty) {
          var fnResps = <FunctionResponse>[
            for (final functionCall in functionCalls)
              await dispatchFunctionCall(functionCall)
          ];
          fnResps.forEach((fnResp) => message += fnResp.toJson().toString());
        }
        print('Response: ${message}');
        yield message;
      }
    } catch (e) {
      print('Error: $e'); // Log any errors
      rethrow; // Re-throw the error after logging it
    }
  }
}
