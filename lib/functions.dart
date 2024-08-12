import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:nimbus/logger.dart';
import 'package:process_run/process_run.dart';

final functions = {
  'runCode': runCode,
};

List<FunctionDeclaration> getGeminiFnDefs() {
  return [runCodeGemini];
}

Future<Map<String, Object?>> runCode(Map<String, Object?> args) async {
  final code = args['code'] as String;
  final results = await run(code);
  for (var result in results) {
    if (result.exitCode == 0) {
      Logger.debug('Command output: ${result.stdout}');
      return {'output': result.stdout.trim()};
    } else {
      Logger.debug('Error running command: ${result.stderr}');
      return {'error': result.stderr.trim()};
    }
  }
  return {'error': 'No result returned from code script'};
}

final runCodeGemini = FunctionDeclaration(
    'runCode',
    'Run code on the User\'s machine',
    Schema.object(properties: {
      'code': Schema.string(
          description: 'The shell command to run.', nullable: false)
    }));
