import 'package:epubx/epubx.dart';
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
    return getChaptersImpl(bookRef, navigationPoints, bookRef.Schema!.Package!);
  }

  static List<EpubChapterRef> getChaptersImpl(
    EpubBookRef bookRef,
    List<EpubNavigationPoint> navigationPoints,
    EpubPackage package,
  ) {
    var result = <EpubChapterRef>[];
    final spineItems = package.Spine!.Items!;
    final manifestItems = package.Manifest!.Items!;

    EpubChapterRef? lastTopLevelChapter;
    EpubNavigationPoint? lastNavPoint;
    for (var i = 0; i < spineItems.length; i++) {
      if (spineItems[i].IsLinear != null && !spineItems[i].IsLinear!) {
        continue;
      }
      final idRef = spineItems[i].IdRef!;
      final manifestItem = manifestItems.cast<EpubManifestItem?>().firstWhere(
            (element) => element?.Id?.toLowerCase() == idRef.toLowerCase(),
            orElse: () => null,
          );
      if (manifestItem == null) {
        continue;
      }
      final navPoint = navigationPoints.cast<EpubNavigationPoint?>().firstWhere(
            (element) =>
                element!.Content!.Source!.toLowerCase() ==
                manifestItem.Href!.toLowerCase(),
            orElse: () => null,
          );
      if (navPoint != null) {
        lastTopLevelChapter = navigationPointToChapter(
          bookRef,
          navPoint,
          package,
        );
        if (lastTopLevelChapter != null) {
          lastNavPoint = navPoint;
          result.add(lastTopLevelChapter);
        }
        continue;
      }
      if (lastNavPoint != null) {
        var found = false;
        for (var childNavPoint in lastNavPoint.ChildNavigationPoints!) {
          if (childNavPoint.Content!.Source!.toLowerCase() ==
              manifestItem.Href!.toLowerCase()) {
            final subChapter = navigationPointToChapter(
              bookRef,
              childNavPoint,
              package,
            );
            if (subChapter != null) {
              lastTopLevelChapter!.SubChapters!.add(subChapter);
              found = true;
              break;
            }
          }
        }
        if (found) {
          continue;
        }
      }
      final point = EpubNavigationPoint();
      point.Content = EpubNavigationContent();
      point.Content!.Source = manifestItem.Href;
      point.Id = manifestItem.Id;
      point.NavigationLabels = <EpubNavigationLabel>[];
      point.NavigationLabels!.add(EpubNavigationLabel()
        ..Text = lastTopLevelChapter != null ? 'Untitled Chapter' : 'Begining');
      point.ChildNavigationPoints = <EpubNavigationPoint>[];
      final subChapter = navigationPointToChapter(
        bookRef,
        point,
        package,
      );
      if (lastTopLevelChapter != null) {
        lastTopLevelChapter.SubChapters!.add(subChapter!);
      } else {
        result.add(subChapter!);
        lastTopLevelChapter = subChapter;
      }
    }
    return result;
  }

  static EpubChapterRef? navigationPointToChapter(
    EpubBookRef bookRef,
    EpubNavigationPoint navigationPoint,
    EpubPackage package,
  ) {
    String? contentFileName;
    String? anchor;
    if (navigationPoint.Content?.Source == null) {
      return null;
    }
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
    chapterRef.SubChapters = [];

    // for (var childNavigationPoint in navigationPoint.ChildNavigationPoints!) {
    //   final subChapter = navigationPointToChapter(
    //     bookRef,
    //     childNavigationPoint,
    //     package,
    //   );
    //   if (subChapter != null) {
    //     chapterRef.SubChapters!.add(subChapter);
    //   }
    // }
    return chapterRef;
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
}
