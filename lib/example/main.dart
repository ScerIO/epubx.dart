import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:epubx/epubx.dart';
import 'package:epubx/example/datasource.dart';
import 'package:epubx/example/epub_parser.dart';
import 'package:epubx/example/parse_paragraph_result.dart';

Future<void> main() async {
  var bytes = await File('test-book.epub').readAsBytes();
  await EpubReader.readBook(bytes);
  return;
}

/*
final datasource = Datasource()..init();
Future main() async {
  final ids = readIdsFromFile().toSet();
  final allIds = List.generate(4000, (index) => index);
  allIds.removeWhere((element) => ids.contains(element));
  for (var i = 0; i < allIds.length; i += 10) {
    final ids =
        List.generate(min(10, allIds.length - i), (index) => allIds[index + i]);
    final futures = ids.map((e) => dealWithBookById(e));
    final res = await Future.wait(futures);
  }

  print('Results written to file.');
}

Future<void> dealWithBookById(int id) async {
  final book = await datasource.getBook(id);
  if (book.id != -1) {
    try {
      final response = await Dio().get(book.fileUrl,
          options: Options(
            responseType: ResponseType.bytes,
          ));
      final data = response.data;
      final epub = await EpubReader.readBook(data);
      final result = await getParagraphsLength(epub);
      await writeResultToFile(book.id, result);
    } catch (_) {
      print(_);
    }
  }
}

Future<int> getParagraphsLength(EpubBook book) async {
  final _chapters = EpubParser.parseChapters(book);
  late final ParseParagraphsResult parseParagraphsResult;

  parseParagraphsResult = EpubParser().parseParagraphs(_chapters);

  return parseParagraphsResult.flatParagraphs.length;
}

Future<void> writeResultToFile(int id, int result) async {
  final outputFile = File(filePath);

  try {
    // Open the file in append mode
    final sink = outputFile.openWrite(mode: FileMode.append);

    // Write the result in the form of "$id - $result"
    sink.write('$id - $result;\n');

    // Close the file
    await sink.close();
  } catch (e) {
    print('Error writing result to file: $e');
  }
}

final filePath = 'result.txt'; // Replace with the actual path to your file

List<int> readIdsFromFile() {
  final file = File(filePath);
  final ids = <int>[];

  try {
    final lines = file.readAsLinesSync();

    for (var line in lines) {
      final parts = line.split(' - ');
      if (parts.length == 2) {
        final id = int.tryParse(parts[0]);
        if (id != null) {
          ids.add(id);
        }
      }
    }
  } catch (e) {
    print('Error reading IDs from file: $e');
  }

  return ids;
}
*/