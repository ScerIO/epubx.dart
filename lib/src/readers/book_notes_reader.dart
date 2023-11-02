import 'dart:async';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:epubx/epubx.dart';

class BookNotesReader {
  static Future<dynamic> readBookNotes(EpubBookRef bookRef) async {
    var noteManifestItem = bookRef.Schema!.Package!.Manifest!.Items!
        .firstWhereOrNull((EpubManifestItem manifestItem) =>
            manifestItem.Id!.toLowerCase().contains('note'));
    if (noteManifestItem == null) {
      throw Exception(
          'Incorrect EPUB manifest: item with ID = \"$noteManifestItem\" is missing.');
    }

    final note = bookRef.Content?.AllFiles?[noteManifestItem.Href];
    final string = await note?.readContentAsText();

    return note;
  }
}
