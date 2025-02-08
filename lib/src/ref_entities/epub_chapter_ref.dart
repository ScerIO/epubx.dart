import 'dart:async';

import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import 'epub_text_content_file_ref.dart';

class EpubChapterRef {
  // Referece to Text content reader.
  late EpubTextContentFileRef epubTextContentFileRef;

  String? Title;
  String? ContentFileName;
  String? Anchor;
  List<EpubChapterRef> SubChapters = [];
  List<EpubTextContentFileRef> OtherChapterFragments = [];

  EpubChapterRef(EpubTextContentFileRef epubTextContentFileRef) {
    this.epubTextContentFileRef = epubTextContentFileRef;
  }

  @override
  int get hashCode {
    var objects = [
      Title.hashCode,
      ContentFileName.hashCode,
      Anchor.hashCode,
      epubTextContentFileRef.hashCode,
      ...SubChapters.map((subChapter) => subChapter.hashCode),
      ...OtherChapterFragments.map((subChapter) => subChapter.hashCode),
    ];
    return hashObjects(objects);
  }

  @override
  bool operator ==(other) {
    if (!(other is EpubChapterRef)) {
      return false;
    }
    return Title == other.Title &&
        ContentFileName == other.ContentFileName &&
        Anchor == other.Anchor &&
        epubTextContentFileRef == other.epubTextContentFileRef &&
        collections.listsEqual(SubChapters, other.SubChapters);
  }

  Future<String> readHtmlContent() async {
    var contentFuture = epubTextContentFileRef.readContentAsText();
    if (OtherChapterFragments.isNotEmpty) {
      var allContentFutures = <Future<String>>[contentFuture];
      for (var fragments in OtherChapterFragments) {
        allContentFutures.add(fragments.readContentAsText());
      }
      return Future.wait(allContentFutures).then((List<String> contents) {
        return contents.join('');
      });
    } else {
      return contentFuture;
    }
  }

  @override
  String toString() {
    return 'Title: $Title, Subchapter count: ${SubChapters.length}';
  }
}
