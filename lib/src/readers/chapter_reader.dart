import 'package:epubx/src/utils/file_name_decoder.dart';

import '../ref_entities/epub_book_ref.dart';
import '../ref_entities/epub_chapter_ref.dart';
import '../ref_entities/epub_text_content_file_ref.dart';
import '../schema/navigation/epub_navigation_point.dart';

class ChapterReader {
  static List<EpubChapterRef> getChapters(EpubBookRef bookRef) {
    if (bookRef.Schema!.Navigation == null) {
      return <EpubChapterRef>[];
    }
    var navigationPoints = bookRef.Schema!.Navigation!.NavMap!.Points!;
    var navigationFileNames = getAllNavigationFileNames(navigationPoints);
    var unmappedChapters = getUnmappedChapters(bookRef, navigationFileNames);
    var hasChapterSplittingIntoFiles =
        hasChapterSplittingInFiles(navigationFileNames);
    return getChaptersImpl(bookRef, navigationPoints, unmappedChapters,
        hasChapterSplittingIntoFiles);
  }

  static List<EpubChapterRef> getChaptersImpl(
    EpubBookRef bookRef,
    List<EpubNavigationPoint> navigationPoints,
    List<String> unmappedChapters,
    bool hasChapterSplittingIntoFiles,
  ) {
    var result = <EpubChapterRef>[];
    for (var navigationPoint in navigationPoints) {
      String? contentFileName;
      String? anchor;
      if (navigationPoint.Content?.Source == null) continue;
      var contentSourceAnchorCharIndex =
          navigationPoint.Content!.Source!.indexOf('#');
      if (contentSourceAnchorCharIndex == -1) {
        contentFileName = navigationPoint.Content!.Source;
        anchor = null;
      } else {
        contentFileName = navigationPoint.Content!.Source!
            .substring(0, contentSourceAnchorCharIndex);
        anchor = navigationPoint.Content!.Source!
            .substring(contentSourceAnchorCharIndex + 1);
      }
      contentFileName = decodeFileName(contentFileName!);
      EpubTextContentFileRef? htmlContentFileRef;
      if (!bookRef.Content!.Html!.containsKey(contentFileName)) {
        throw Exception(
            'Incorrect EPUB manifest: item with href = \"$contentFileName\" is missing.');
      }

      htmlContentFileRef = bookRef.Content!.Html![contentFileName];
      var chapterRef = EpubChapterRef(htmlContentFileRef);
      chapterRef.ContentFileName = contentFileName;
      chapterRef.Anchor = anchor;
      chapterRef.Title = navigationPoint.NavigationLabels!.first.Text;
      chapterRef.SubChapters = getChaptersImpl(
          bookRef,
          navigationPoint.ChildNavigationPoints!,
          unmappedChapters,
          hasChapterSplittingIntoFiles);
      if (hasChapterSplittingIntoFiles) {
        addSplitChaptersToRef(bookRef, chapterRef, unmappedChapters);
      }

      result.add(chapterRef);
    }
    ;
    return result;
  }

  static List<String> getAllNavigationFileNames(
      List<EpubNavigationPoint> points) {
    var result = <String>[];
    for (var point in points) {
      if (point.Content?.Source != null) {
        result.add(point.Content!.Source!);
      }
      result
          .addAll(getAllNavigationFileNames(point.ChildNavigationPoints ?? []));
    }
    return result;
  }

  /// Sometimes chapters are split into multiple files,
  /// but the split files are not listed in the navigation.
  /// We need to find these files and add them to the chapter as [OtherContentFileNames].
  static List<String> getUnmappedChapters(
      EpubBookRef bookRef, List<String> navigationFileNames) {
    var allFileNames = Set<String>.from(bookRef.Content!.Html!.keys);
    return allFileNames.difference(navigationFileNames.toSet()).toList();
  }

  /// This checks if the chapters are split into multiple files by
  /// 1. Checking if the file names contain "_split_".
  /// 2. Two chapters listed in the navigation file should not have the same file name part before "_split_".
  static bool hasChapterSplittingInFiles(List<String> navigationFileNames) {
    var uniqueFileNameParts = <String>{};
    for (var fileName in navigationFileNames) {
      if (fileName.contains('_split_')) {
        var baseName = fileName.split('_split_')[0];
        if (uniqueFileNameParts.contains(baseName)) {
          return false;
        }
        uniqueFileNameParts.add(baseName);
      }
    }
    return uniqueFileNameParts.isNotEmpty;
  }

  static void addSplitChaptersToRef(
    EpubBookRef bookRef,
    EpubChapterRef chapterRef,
    List<String> unmappedChapters,
  ) {
    if (!chapterRef.ContentFileName!.contains('_split_')) {
      return;
    }

    var baseName = chapterRef.ContentFileName!.split('_split_')[0];
    var addedChapters = <String>[]; // List to store items for removal

    for (var fileName in unmappedChapters) {
      if (fileName.contains('${baseName}_split') &&
          fileName != chapterRef.ContentFileName) {
        chapterRef.otherTextContentFileRefs
            .add(bookRef.Content!.Html![fileName]!);
        chapterRef.OtherContentFileNames.add(fileName);
        addedChapters.add(fileName); // Add to removal list
      }
    }
    unmappedChapters
        .removeWhere((fileName) => addedChapters.contains(fileName));
  }
}
