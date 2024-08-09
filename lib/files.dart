import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';

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
      // if (await FileSystemEntity.isFile(entity.path)) {
      //   paths.add(entity.path);
      // }
      final mime = lookupMimeType(entity.path);
      if (mime == null) continue;
      if (mime.startsWith('text')) {
        paths.add(entity.path);
      }
      if (mime.startsWith('image')) {
        paths.add(entity.path);
      }
    }
    return paths;
  }

  static Future<Part> getPart(String path) async {
    final mime = lookupMimeType(path);
    if (mime != null && mime.startsWith('image')) {
      return DataPart(mime, await File(path).readAsBytes());
    }
    if (mime != null && mime.startsWith('text')) {
      return TextPart(await File(path).readAsString());
    }
    throw Exception('Unsupported file type called');
  }

  // Future<void> _extractTextFromPdf(String filePath) async {
  //   PDFDoc doc = await PDFDoc.fromPath(filePath);
  //   String text = await doc.text;
  // }

  // Future<void> _extractTextFromDocx(String filePath) async {
  //   final docx = await Docx.fromFile(File(filePath));
  //   final text = docx.getFullText();
  // }

  // Future<void> _extractDataFromExcel(String filePath) async {
  //   var bytes = File(filePath).readAsBytesSync();
  //   var excel = Excel.decodeBytes(bytes);
  //   String data = '';
  //   for (var table in excel.tables.keys) {
  //     data += 'Table: $table\n';
  //     excel.tables[table]?.rows?.forEach((row) {
  //       data += row.map((cell) => cell?.value ?? '').join(', ') + '\n';
  //     });
  //   }
  // }
}
