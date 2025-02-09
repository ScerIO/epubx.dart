import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:image/image.dart' as images;
import 'package:logger/logger.dart';

import '../ref_entities/epub_book_ref.dart';
import '../ref_entities/epub_byte_content_file_ref.dart';
import '../schema/opf/epub_manifest_item.dart';
import '../schema/opf/epub_metadata_meta.dart';

class BookCoverReader {
  static final logger = Logger();

  static Future<images.Image?> readBookCover(EpubBookRef bookRef) async {
    var metaItems = bookRef.Schema!.Package!.Metadata!.MetaItems;
    if (metaItems == null) return null;
    var coverMetaItem = metaItems.firstWhereOrNull(
        (EpubMetadataMeta metaItem) =>
            metaItem.Name != null && metaItem.Name!.toLowerCase() == 'cover');
    var coverManifestId;
    var coverManifestSearchId = 'cover';
    if (coverMetaItem != null &&
        coverMetaItem.Content != null &&
        coverMetaItem.Content!.isNotEmpty) {
      coverManifestId = coverMetaItem.Content!.toLowerCase();
    } else {
      logger.e('Cover id is not in manifest.');
    }
    var coverManifestItem;
    if (coverManifestId != null) {
      coverManifestItem = bookRef.Schema!.Package!.Manifest!.Items!
          .firstWhereOrNull((EpubManifestItem manifestItem) =>
              manifestItem.Id!.toLowerCase() == coverManifestId);
    }
    // If manifest item with cover id is not found, search for item with text "cover" in id
    if (coverManifestItem == null) {
      var coverManifestItems = bookRef.Schema!.Package!.Manifest!.Items!
          .where((EpubManifestItem manifestItem) =>
              manifestItem.Id!.toLowerCase().contains(coverManifestSearchId))
          .toList();
      if (coverManifestItems.length == 1) {
        coverManifestItem = coverManifestItems.first;
      } else {
        coverManifestItem = coverManifestItems.firstWhereOrNull(
            (EpubManifestItem manifestItem) =>
                manifestItem.MediaType?.contains('image') ?? false);
      }
    }
    if (coverManifestItem == null) {
      logger.e(
          'Incorrect EPUB manifest: item with ID = \"$coverManifestId\" is missing.');
      return null;
    }

    EpubByteContentFileRef? coverImageContentFileRef;
    if (!bookRef.Content!.Images!.containsKey(coverManifestItem.Href)) {
      logger.e(
          'Incorrect EPUB manifest: item with href = \"${coverManifestItem.Href}\" is missing.');
      return null;
    }

    coverImageContentFileRef = bookRef.Content!.Images![coverManifestItem.Href];
    try {
      var coverImageContent =
          await coverImageContentFileRef!.readContentAsBytes();
      var retval = images.decodeImage(Uint8List.fromList(coverImageContent));
      return retval;
    } catch (e) {
      logger.e('Error reading cover image content: $e');
      return null;
    }
  }
}
