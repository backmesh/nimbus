import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:process_run/process_run.dart';

final functions = {
  'runCode': runCode,
  // getOSInfoFunction.name: getOSInfo
};

List<FunctionDeclaration> getGeminiFnDefs() {
  return [runCodeGemini];
}

Future<Map<String, Object?>> runCode(Map<String, Object?> args) async {
  final code = args['code'] as String;
  final results = await run(code);
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
  return {'error': 'No result returned from code script'};
}

final runCodeGemini = FunctionDeclaration(
    'runCode',
    'Run code on the User\'s machine',
    Schema.object(properties: {
      'code': Schema.string(
          description: 'The shell command to run.', nullable: false)
    }));

// Future<Map<String, Object?>> getOSInfo(Map<String, Object?> args) async {
//   final os = Platform.operatingSystem;
//   final osVersion = Platform.operatingSystemVersion;
//   return {'os': os, 'version': osVersion};
// }

// final getOSInfoFunction = FunctionDeclaration(
//     'getOSInfo',
//     'Get the operating system information.',
//     Schema.object(properties: {
//       'os': Schema.string(description: 'The operating system name.'),
//       'version': Schema.string(description: 'The operating system version.')
//     }));