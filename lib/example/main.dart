import 'dart:io';

import 'package:epubx/epubx.dart';

Future main() async {
  print(1);
  var bytes = await File('test-book.epub').readAsBytes();
  // final byteData = await rootBundle.load(assetName);
//  final bytes = byteData.buffer.asUint8List();
  return EpubReader.readBook(bytes);
}
