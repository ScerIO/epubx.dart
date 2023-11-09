import 'dart:async';

import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import 'epub_text_content_file_ref.dart';

class EpubChapterRef {
  EpubTextContentFileRef? epubTextContentFileRef;

  String? Title;
  String? ContentFileName;
  String? Anchor;
  List<EpubChapterRef>? SubChapters;

  EpubChapterRef(EpubTextContentFileRef? epubTextContentFileRef) {
    this.epubTextContentFileRef = epubTextContentFileRef;
  }

  @override
  int get hashCode {
    var objects = [
      Title.hashCode,
      ContentFileName.hashCode,
      Anchor.hashCode,
      epubTextContentFileRef.hashCode,
      ...SubChapters?.map((subChapter) => subChapter.hashCode) ?? [0],
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
    final content = await epubTextContentFileRef!.readContentAsText();
    final normalized = _replaceTagsWithTrailingSolidus(content);
    return normalized;
  }

  String _replaceTagsWithTrailingSolidus(String htmlContent) {
    // Define a regular expression to match all tags with trailing solidus
    final tagWithSolidusRegex = RegExp(r'<(\w+)([^>]*)/>');

    // Use the replaceAll method to replace all occurrences of the matched pattern
    var modifiedHtml =
        htmlContent.replaceAllMapped(tagWithSolidusRegex, (match) {
      // Extract the tag name and attributes from the original match
      var tagName = match.group(1) ?? '';
      var attributes = match.group(2) ?? '';

      // Replace the self-closing syntax with the standard opening and closing tag
      return '<$tagName$attributes></$tagName>';
    });

    return modifiedHtml;
  }

  @override
  String toString() {
    return 'Title: $Title, Subchapter count: ${SubChapters!.length}';
  }
}
