import 'dart:io';

import 'package:epubx/epubx.dart';
import 'package:html/parser.dart';

Future main() async {
  print(1);
  var bytes = await File('test-book.epub').readAsBytes();
 // final byteData = await rootBundle.load(assetName);
//  final bytes = byteData.buffer.asUint8List();
  return EpubReader.readBook(bytes);

 /* final doc = parse(htmlTest);
 final item =  doc.getElementById("uGqeclf8MxKocbEYtWPCXu5");
  htmlTest.indexOf(item!.outerHtml);
 final allitems = doc.querySelectorAll("*");
 print(1); */
}


