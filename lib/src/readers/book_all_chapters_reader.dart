import 'dart:async';

import 'package:epubx/epubx.dart';
import 'package:epubx/src/ref_entities/epub_text_content_file_ref.dart';

class BookAllChaptersReader {
  static Future<List<EpubChapter>> readAllChapters(EpubBookRef bookRef) async {
    try {
      /*  var noteManifestItem = bookRef.Schema!.Package!.Manifest!.Items!
          .firstWhereOrNull((EpubManifestItem manifestItem) =>
              manifestItem.Id!.toLowerCase().contains('note'));
      if (noteManifestItem == null) {
        throw Exception(
            'Incorrect EPUB manifest: item with ID = \"$noteManifestItem\" is missing.');
      }

      final note = bookRef.Content?.AllFiles?[noteManifestItem.Href];
      final noteText = note as EpubTextContentFileRef;
      final epubChapter = EpubChapterRef(noteText);
      epubChapter.ContentFileName = noteText.FileName;
      epubChapter.Title = '\$notes-found-in-directory\$';
      final result = await EpubReader.readChapters([epubChapter]);
      return result.first;*/
      final allFiles = bookRef.Content?.AllFiles?.values
          .where(
            (element) =>
                element is EpubTextContentFileRef &&
                (element.FileName?.endsWith('html') == true ||
                    element.FileName?.endsWith('xml') == true),
          )
          .toList();
      final allChapterRefs = allFiles
          ?.map(
            (e) => EpubChapterRef(e as EpubTextContentFileRef)
              ..Title = e.FileName
              ..ContentFileName = e.FileName,
          )
          .toList();

      final allChapters = await EpubReader.readChapters(allChapterRefs ?? []);

      return allChapters;
    } catch (e) {
      print(e);
      return [];
    }
  }
}
