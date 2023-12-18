import 'dart:async';

import 'package:archive/archive.dart';
import 'package:epubx/src/core/helper/extensions.dart';
import 'package:epubx/src/utils/html_combiner.dart';

import 'entities/epub_book.dart';
import 'entities/epub_byte_content_file.dart';
import 'entities/epub_chapter.dart';
import 'entities/epub_content.dart';
import 'entities/epub_content_file.dart';
import 'entities/epub_text_content_file.dart';
import 'entities/tag_position.dart';
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
import 'package:html/dom.dart';

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
    result.Chapters!.forEach((element) {
      concatenateChapterContent(element);
    });

    final allChapters = await epubBookRef.getAllChapters();
    result.Chapters = mixChapters(
      result.Chapters ?? [],
      allChapters,
      epubBookRef,
    );
    return result;
  }

  static List<EpubChapter> getAllChapters(
      List<EpubChapter> chapters,
      ) {
    final list = [...chapters];
    chapters.forEach((element) {
      if (element.SubChapters?.isNotEmpty ?? false) {
        list.addAll(
          getAllChapters(element.SubChapters!),
        );
      }
    });
    return list;
  }

  static List<EpubChapter> mixChapters(List<EpubChapter> realChapters,
      List<EpubChapter> allChapters, EpubBookRef ref) {
    //result list
    final mixedList = <EpubChapter>[];
    //combined htmls of notes (untracked chapter with name contains 'note'
    //and all untracked chapters after last tracked chapter)

    //and begin (untracked chapters before first tracked chapter)
    var notesHtml = '';
    var beginHtml = '';
    //lists of those chapters
    final beginChapters = <EpubChapter>[];
    final notesChapters = <EpubChapter>[];
    final untrackedManifestItems = <String?>[];
    //names of tracked chapters
    final allRealChapters = getAllChapters(realChapters);

    //index of the first tracked chapter in the whole list
    final firstChapterIndex = allChapters.indexWhere(
          (element) => allRealChapters
          .any((real) => real.ContentFileName == element.ContentFileName),
    );
    final manifestItems = ref.Schema?.Package?.Manifest?.Items;

    if (manifestItems != null) {
      final firstChapterManifestIndex = manifestItems.indexWhere((element) =>
          allRealChapters.any((real) => real.ContentFileName == element.Href));

      final lastChapterManifestIndex = manifestItems.lastIndexWhere((element) =>
          allRealChapters.any((real) => real.ContentFileName == element.Href));

      //looking through all manifest items to find html files that are not tracked,
      //than put them in notes or begin
      EpubChapter? lastChapter;
      for (var i = 0; i < manifestItems.length; i++) {
        final manifestItem = manifestItems[i];
        if (manifestItem.Href?.isFileHtml() ?? false) {
          final realChaptersFound = allRealChapters.where(
                (real) => real.ContentFileName == manifestItem.Href,
          );
          if (realChaptersFound.isNotEmpty) {
            realChaptersFound.forEach((element) {
              if (realChapters.contains(element)) {
                mixedList.add(element);
              }
              lastChapter = element;
            });
          } else {
            final chapter = allChapters.firstWhere(
                  (element) => element.ContentFileName == manifestItem.Href,
              orElse: () => EpubChapter()..Title = 'Fake1 | 9Title',
            );
            if (chapter.Title != 'Fake1 | 9Title') {
              if (chapter.Title?.contains('note') ?? false) {
                notesChapters.add(chapter);
              } else {
                if (i < firstChapterManifestIndex) {
                  beginChapters.add(chapter);
                } else if (i > lastChapterManifestIndex) {
                  notesChapters.add(chapter);
                } else {
                  untrackedManifestItems.add(chapter.ContentFileName);
                  lastChapter?.HtmlContent = combineHtmls(
                      lastChapter?.HtmlContent, chapter.HtmlContent);
                }
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
          allRealChapters
              .any((real) => real.ContentFileName == chapter.ContentFileName) ||
          untrackedManifestItems.contains(
            chapter.ContentFileName,
          )) {
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
    print(1);

    return result;
  }

  static List<TagPosition> getChapterIdsInFile(
      List<EpubChapterRef> chapterRefs, Document htmlDocument) {
    final chapterIdElements = chapterRefs.map((ref) {
      final element = htmlDocument.getElementById(ref.Anchor ?? '');
      return element;
    }).toList();

    final chapterIds = chapterIdElements.map((element) {
      final startIndex = htmlDocument.outerHtml.indexOf(element!.outerHtml);
      final lastIndex = startIndex + element.outerHtml.length;
      return TagPosition(
        firstCharIndex: startIndex,
        lastCharIndex: lastIndex,
      );
    }).toList();
    return chapterIds;
  }

  static int? firstSubChapterFrom(List<TagPosition> subIds, int chapterId) {
    int? minId;
    subIds.forEach((element) {
      if (element.firstCharIndex >= chapterId &&
          (minId == null || element.firstCharIndex < minId!)) {
        minId = element.firstCharIndex;
      }
    });
    return minId;
  }

  static Future<List<EpubChapter>> readChaptersFromFile(
      List<EpubChapterRef> chapterRefs) async {
    if (chapterRefs.isEmpty) {
      return [];
    }

    final fileContent = await chapterRefs.first.readHtmlContent();
    final htmlDocument = parse(fileContent);
    // var allElements = htmlDocument.querySelectorAll('*');
    final chapters = chapterRefs
        .map(
          (ref) => EpubChapter()
        ..Title = ref.Title
        ..ContentFileName = ref.ContentFileName
        ..Anchor = ref.Anchor,
    )
        .toList();
    if (chapterRefs.length > 1) {
      final chapterIds = getChapterIdsInFile(chapterRefs, htmlDocument);

      for (var i = 0; i < chapterIds.length; i++) {
        var lastIndex = i != chapterIds.length - 1 ?  chapterIds[i + 1].firstCharIndex - 1 : htmlDocument.outerHtml.length - 1 ;
        if (chapterRefs[i].SubChapters?.isNotEmpty == true) {
          final subIds =
          getChapterIdsInFile(chapterRefs[i].SubChapters!, htmlDocument);
          final firstSubId =
          firstSubChapterFrom(subIds, chapterIds[i].firstCharIndex);
          if (firstSubId != null &&
              firstSubId! < chapterIds[i + 1].firstCharIndex) {
            lastIndex = firstSubId;
          }
        }
        if (i == chapterIds.length - 1) {
          lastIndex = htmlDocument.outerHtml.length - 1;
        }
        chapters[i].HtmlContent = htmlDocument.outerHtml.substring(
          chapterIds[i].firstCharIndex,
          lastIndex,
        );
      }
    } else {
      chapters.first.HtmlContent =
      chapterRefs.first.SubChapters?.isNotEmpty == true
          ? htmlDocument.outerHtml.substring(0, 20)
          : htmlDocument.outerHtml;
    }
    final subChaptersFuture =
    chapterRefs.map((ref) => readChapters(ref.SubChapters ?? []));
    final subChapters = await Future.wait(subChaptersFuture);
    for (var i = 0; i < chapters.length; i++) {
      chapters[i].SubChapters = subChapters[i];
    }
    return chapters;
  }

  static void concatenateChapterContent(EpubChapter chapter) {
    if (chapter.SubChapters?.isNotEmpty ?? false) {
      for (var subchapter in chapter.SubChapters!) {
        concatenateChapterContent(subchapter);
      }
      var count = 0;
      for (var i = 0; i < chapter.SubChapters!.length; i++) {
        final subChapter = chapter.SubChapters![i];
        if (subChapter.Title?.isBlank() ?? true) {
          chapter.HtmlContent =
              combineHtmls(chapter.HtmlContent, subChapter.HtmlContent);

          count++;
        } else {
          break;
        }
      }
      chapter.SubChapters = chapter.SubChapters!.skip(count).toList();

      // Recursively process subchapters
    }
  }
}
