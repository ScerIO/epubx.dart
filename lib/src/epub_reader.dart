import 'dart:async';

import 'package:archive/archive.dart';

import 'entities/epub_book.dart';
import 'entities/epub_byte_content_file.dart';
import 'entities/epub_chapter.dart';
import 'entities/epub_content.dart';
import 'entities/epub_content_file.dart';
import 'entities/epub_text_content_file.dart';
import 'readers/content_reader.dart';
import 'readers/schema_reader.dart';
import 'ref_entities/epub_book_ref.dart';
import 'ref_entities/epub_byte_content_file_ref.dart';
import 'ref_entities/epub_chapter_ref.dart';
import 'ref_entities/epub_content_file_ref.dart';
import 'ref_entities/epub_content_ref.dart';
import 'ref_entities/epub_text_content_file_ref.dart';
import 'schema/opf/epub_metadata_creator.dart';
import 'package:html/parser.dart';

/// A class that provides the primary interface to read Epub files.
///
/// To open an Epub and load all data at once use the [readBook()] method.
///
/// To open an Epub and load only basic metadata use the [openBook()] method.
/// This is a good option to quickly load text-based metadata, while leaving the
/// heavier lifting of loading images and main content for subsequent operations.
///
/// ## Example
/// ```dart
/// // Read the basic metadata.
/// EpubBookRef epub = await EpubReader.openBook(epubFileBytes);
/// // Extract values of interest.
/// String title = epub.Title;
/// String author = epub.Author;
/// var metadata = epub.Schema.Package.Metadata;
/// String genres = metadata.Subjects.join(', ');
/// ```
class EpubReader {
  /// Loads basics metadata.
  ///
  /// Opens the book asynchronously without reading its main content.
  /// Holds the handle to the EPUB file.
  ///
  /// Argument [bytes] should be the bytes of
  /// the epub file you have loaded with something like the [dart:io] package's
  /// [readAsBytes()].
  ///
  /// This is a fast and convenient way to get the most important information
  /// about the book, notably the [Title], [Author] and [AuthorList].
  /// Additional information is loaded in the [Schema] property such as the
  /// Epub version, Publishers, Languages and more.
  static Future<EpubBookRef> openBook(FutureOr<List<int>> bytes) async {
    List<int> loadedBytes;
    if (bytes is Future) {
      loadedBytes = await bytes;
    } else {
      loadedBytes = bytes;
    }

    var epubArchive = ZipDecoder().decodeBytes(loadedBytes);

    var bookRef = EpubBookRef(epubArchive);
    bookRef.Schema = await SchemaReader.readSchema(epubArchive);
    bookRef.Title = bookRef.Schema!.Package!.Metadata!.Titles!
        .firstWhere((String name) => true, orElse: () => '');
    bookRef.AuthorList = bookRef.Schema!.Package!.Metadata!.Creators!
        .map((EpubMetadataCreator creator) => creator.Creator)
        .toList();
    bookRef.Author = bookRef.AuthorList!.join(', ');
    bookRef.Content = ContentReader.parseContentMap(bookRef);
    return bookRef;
  }

  /// Opens the book asynchronously and reads all of its content into the memory. Does not hold the handle to the EPUB file.
  static Future<EpubBook> readBook(FutureOr<List<int>> bytes) async {
    var result = EpubBook();
    List<int> loadedBytes;
    if (bytes is Future) {
      loadedBytes = await bytes;
    } else {
      loadedBytes = bytes;
    }

    var epubBookRef = await openBook(loadedBytes);
    result.Schema = epubBookRef.Schema;
    result.Title = epubBookRef.Title;
    result.AuthorList = epubBookRef.AuthorList;
    result.Author = epubBookRef.Author;
    result.Content = await readContent(epubBookRef.Content!);
    result.CoverImage = await epubBookRef.readCover();
    var chapterRefs = await epubBookRef.getChapters();
    result.Chapters = await readChapters(chapterRefs);

    final allChapters = await epubBookRef.getAllChapters();
    result.Chapters = mixChapters(
      result.Chapters ?? [],
      allChapters,
      epubBookRef,
    );
    return result;
  }

  static List<EpubChapter> mixChapters(List<EpubChapter> realChapters,
      List<EpubChapter> allChapters, EpubBookRef ref) {
    final mixedList = realChapters;
    var notesHtml = '';
    var beginHtml = '';
    final beginChapters = <EpubChapter>[];
    final notesChapters = <EpubChapter>[];

    final realHtmls = realChapters.map((e) => e.HtmlContent);
    final realNames = realChapters.map((e) => e.ContentFileName);
    final firstChapterIndex = allChapters
        .indexWhere((element) => realHtmls.contains(element.HtmlContent));
    final manifestItems = ref.Schema?.Package?.Manifest?.Items;

    if (manifestItems != null) {
      final firstChapterManifestIndex = manifestItems
          .indexWhere((element) => realNames.contains(element.Href));
      for (var i = 0; i < manifestItems.length; i++) {
        final manifestItem = manifestItems[i];
        if (manifestItem.Href?.endsWith('html') == true ||
            manifestItem.Href?.endsWith('xml') == true) {
          final realChapter = realChapters.firstWhere(
            (element) => element.ContentFileName == manifestItem.Href,
            orElse: () => EpubChapter()..Title = 'Fake1 | 9Title',
          );

          if (realChapter.Title != 'Fake1 | 9Title') {
            //  mixedList.add(realChapter);
          } else {
            final chapter = allChapters.firstWhere(
              (element) => element.ContentFileName == manifestItem.Href,
              orElse: () => EpubChapter()..Title = 'Fake1 | 9Title',
            );
            if (chapter.Title != 'Fake1 | 9Title') {
              if (i < firstChapterManifestIndex) {
                beginChapters.add(chapter);
              } else {
                notesChapters.add(chapter);
              }
            }
          }
        }
      }
    }
    for (var i = 0; i < allChapters.length; i++) {
      final chapter = allChapters[i];
      if (beginChapters.contains(chapter) ||
          notesChapters.contains(chapter) ||
          realHtmls.contains(chapter.HtmlContent)) {
      } else {
        if (i < firstChapterIndex) {
          beginChapters.add(chapter);
        } else {
          notesChapters.add(chapter);
        }
      }
    }

    beginHtml = beginChapters.toHtml();
    notesHtml = notesChapters.toHtml();

    if (beginHtml.isNotEmpty) {
      final beginChapter = EpubChapter();
      beginChapter.HtmlContent = beginHtml;
      beginChapter.Title = '\$begin-found-in-directory\$';
      beginChapter.ContentFileName = 'begin';

      mixedList.insert(0, beginChapter);
    }

    if (notesHtml.isNotEmpty) {
      final notesChapter = EpubChapter();
      notesChapter.HtmlContent = notesHtml;
      notesChapter.Title = '\$notes-found-in-directory\$';
      notesChapter.ContentFileName = 'notes';

      mixedList.add(notesChapter);
    }

    return mixedList;
  }

  static Future<EpubContent> readContent(EpubContentRef contentRef) async {
    var result = EpubContent();
    result.Html = await readTextContentFiles(contentRef.Html!);
    result.Css = await readTextContentFiles(contentRef.Css!);
    result.Images = await readByteContentFiles(contentRef.Images!);
    result.Fonts = await readByteContentFiles(contentRef.Fonts!);
    result.AllFiles = <String, EpubContentFile>{};

    result.Html!.forEach((String? key, EpubTextContentFile value) {
      result.AllFiles![key!] = value;
    });
    result.Css!.forEach((String? key, EpubTextContentFile value) {
      result.AllFiles![key!] = value;
    });

    result.Images!.forEach((String? key, EpubByteContentFile value) {
      result.AllFiles![key!] = value;
    });
    result.Fonts!.forEach((String? key, EpubByteContentFile value) {
      result.AllFiles![key!] = value;
    });

    await Future.forEach(contentRef.AllFiles!.keys, (dynamic key) async {
      if (!result.AllFiles!.containsKey(key)) {
        result.AllFiles![key] =
            await readByteContentFile(contentRef.AllFiles![key]!);
      }
    });

    return result;
  }

  static Future<Map<String, EpubTextContentFile>> readTextContentFiles(
      Map<String, EpubTextContentFileRef> textContentFileRefs) async {
    var result = <String, EpubTextContentFile>{};

    await Future.forEach(textContentFileRefs.keys, (dynamic key) async {
      EpubContentFileRef value = textContentFileRefs[key]!;
      var textContentFile = EpubTextContentFile();
      textContentFile.FileName = value.FileName;
      textContentFile.ContentType = value.ContentType;
      textContentFile.ContentMimeType = value.ContentMimeType;
      textContentFile.Content = await value.readContentAsText();
      result[key] = textContentFile;
    });
    return result;
  }

  static Future<Map<String, EpubByteContentFile>> readByteContentFiles(
      Map<String, EpubByteContentFileRef> byteContentFileRefs) async {
    var result = <String, EpubByteContentFile>{};
    await Future.forEach(byteContentFileRefs.keys, (dynamic key) async {
      result[key] = await readByteContentFile(byteContentFileRefs[key]!);
    });
    return result;
  }

  static Future<EpubByteContentFile> readByteContentFile(
      EpubContentFileRef contentFileRef) async {
    var result = EpubByteContentFile();

    result.FileName = contentFileRef.FileName;
    result.ContentType = contentFileRef.ContentType;
    result.ContentMimeType = contentFileRef.ContentMimeType;
    result.Content = await contentFileRef.readContentAsBytes();

    return result;
  }

  static Future<List<EpubChapter>> readChapters(
      List<EpubChapterRef> chapterRefs) async {
    if (chapterRefs.isEmpty) {
      return [];
    }
    var result = <EpubChapter>[];
    final fileIds = <String, List<EpubChapterRef>>{};
    chapterRefs.forEach((ref) {
      if (fileIds.containsKey(ref.ContentFileName)) {
        fileIds[ref.ContentFileName]!.add(ref);
      } else {
        fileIds[ref.ContentFileName!] = [ref];
      }
    });

    await Future.forEach(fileIds.values,
        (List<EpubChapterRef> fileChaptersRefs) async {
      final readChapters = await readChaptersFromFile(fileChaptersRefs);
      result.addAll(readChapters);
    });

    /*await Future.forEach(chapterRefs, (EpubChapterRef chapterRef) async {
      var chapter = EpubChapter();

      chapter.Title = chapterRef.Title;
      chapter.ContentFileName = chapterRef.ContentFileName;
      chapter.Anchor = chapterRef.Anchor;
      chapter.HtmlContent = await chapterRef.readHtmlContent();
      chapter.SubChapters = await readChapters(chapterRef.SubChapters ?? []);

      result.add(chapter);
    });
  */
    return result;
  }

  static Future<List<EpubChapter>> readChaptersFromFile(
      List<EpubChapterRef> chapterRefs) async {
    if (chapterRefs.isEmpty) {
      return [];
    }
    final fileContent = await chapterRefs.first.readHtmlContent();
    final chapters = chapterRefs
        .map(
          (ref) => EpubChapter()
            ..Title = ref.Title
            ..ContentFileName = ref.ContentFileName
            ..Anchor = ref.Anchor,
        )
        .toList();
    if (chapterRefs.length > 1) {
      final htmlDocument = parse(fileContent);

      final chapterIdElements = chapterRefs
          .map((ref) => htmlDocument.getElementById(ref.Anchor ?? ''))
          .toList();

      final allElements = htmlDocument.querySelectorAll('*');
      final chapterIds =
          chapterIdElements.map((e) => allElements.indexOf(e!)).toList();

      for (var i = 0; i < chapterIds.length; i++) {
        chapters[i].HtmlContent = allElements
            .sublist(
                chapterIds[i],
                i == chapterIds.length - 1
                    ? allElements.length - 1
                    : chapterIds[i + 1] - 1)
            .map((e) => e.outerHtml)
            .join();
      }
    } else {
      chapters.first.HtmlContent = fileContent;
    }
    final subChaptersFuture =
        chapterRefs.map((ref) => readChapters(ref.SubChapters ?? []));
    final subChapters = await Future.wait(subChaptersFuture);
    for (var i = 0; i < chapters.length; i++) {
      chapters[i].SubChapters = subChapters[i];
    }
    return chapters;
  }
}
