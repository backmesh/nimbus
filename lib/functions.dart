import 'package:process_run/process_run.dart';

final functions = {
  'runCode': runCode,
  // getOSInfoFunction.name: getOSInfo
};

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
