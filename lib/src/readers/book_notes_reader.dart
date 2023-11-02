import 'dart:async';

import 'package:collection/collection.dart' show IterableExtension;

import '../ref_entities/epub_book_ref.dart';
import '../schema/opf/epub_manifest_item.dart';
import '../schema/opf/epub_metadata_meta.dart';

class BookNotesReader {
  static Future<dynamic> readBookNotes(EpubBookRef bookRef) async {
    var metaItems = bookRef.Schema!.Package!.Metadata!.MetaItems;
    if (metaItems == null || metaItems.isEmpty) return null;

    var coverMetaItem = metaItems.firstWhereOrNull(
        (EpubMetadataMeta metaItem) =>
            metaItem.Name != null &&
            metaItem.Name!.toLowerCase().contains('note'));
    if (coverMetaItem == null) return null;
    if (coverMetaItem.Content == null || coverMetaItem.Content!.isEmpty) {
      throw Exception(
          'Incorrect EPUB metadata: cover item content is missing.');
    }

    var coverManifestItem = bookRef.Schema!.Package!.Manifest!.Items!
        .firstWhereOrNull((EpubManifestItem manifestItem) =>
            manifestItem.Id!.toLowerCase() ==
            coverMetaItem.Content!.toLowerCase());
    if (coverManifestItem == null) {
      throw Exception(
          'Incorrect EPUB manifest: item with ID = \"${coverMetaItem.Content}\" is missing.');
    }

    final note = bookRef.Content?.AllFiles?[coverManifestItem.Href];

    return note;
  }
}
