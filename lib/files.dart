import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:path_provider/path_provider.dart';
// https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types
import 'package:mime/mime.dart';

// created this whitelist through trial and error
// have to be careful with google gen ai package updates
// the docs have no official list and a commment in the samples says
// only image/* mime types work but pdf does and svg and heic do not
// https://github.com/google-gemini/generative-ai-dart/blob/9ea128fa6ca8b4e387973e0bf28eb2fe9feeea6a/samples/dart/bin/advanced_text_and_image.dart#L42
// https://github.com/google-gemini/generative-ai-dart/blob/9ea128fa6ca8b4e387973e0bf28eb2fe9feeea6a/samples/flutter_app/lib/main.dart#L226
const SUPPORTED_MIMES = [
  'image/png',
  'image/jpg',
  'image/jpeg',
  'application/pdf',
];

class Files {
  static Future<List<String>> getSupportedFilePaths() async {
    final docs = await getApplicationDocumentsDirectory();
    final downloads = await getDownloadsDirectory();
    final docDir = Directory(docs.path);
    final downloadDir = downloads != null ? Directory(downloads.path) : null;
    final docEnts = await docDir.list().toList();
    final downloadEnts = await downloadDir?.list().toList() ?? List.empty();
    List<String> paths = [];
    for (final entity in docEnts.followedBy(downloadEnts)) {
      final mime = lookupMimeType(entity.path);
      if (mime == null) continue;
      if (isMimeSupported(mime)) {
        paths.add(entity.path);
      }
    }
    return paths;
  }

  // if the file is not supported it returns nothing
  // and the file is ignored to avoid gemini from erroring
  static Future<Part?> getPart(String path) async {
    final mime = lookupMimeType(path);
    print('get message part for $path with mime $mime');
    if (mime == null) return null;
    if (SUPPORTED_MIMES.contains(mime)) {
      return DataPart(mime, await File(path).readAsBytes());
    }
    if (mime.startsWith('text')) {
      return TextPart(await File(path).readAsString());
    }
    if (mime == 'application/json') {
      return TextPart(await File(path).readAsString());
    }
    return null;
  }

  static bool isMimeSupported(String mime) {
    if (SUPPORTED_MIMES.contains(mime)) return true;
    if (mime.startsWith('text')) return true;
    if (mime == 'application/json') return true;
    return false;
  }
}
