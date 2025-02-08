import 'package:epubx/epubx.dart';
import 'package:epubx/src/utils/file_name_decoder.dart';

import '../ref_entities/epub_text_content_file_ref.dart';

import 'package:tuple/tuple.dart';

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

    // This map is used to keep track of the chapters that are found in TOC.
    // These chapters can have spline items as children and we need to add them to the correct parent.
    final Map<EpubNavigationPoint, EpubChapterRef> navPointMap = {};

    // Last chapter is used to add OtherFragments whenever a chapter is not found in TOC.
    EpubChapterRef? lastChapter;
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
            (element) => checkEqual(element!, manifestItem),
            orElse: () => null,
          );
      if (navPoint != null) {
        // Found in TOC. Add chapter.
        lastChapter = navigationPointToChapter(
          bookRef,
          navPoint,
        );
        if (lastChapter != null) {
          result.add(lastChapter);
          navPointMap[navPoint] = lastChapter;
        }
        continue;
      }
      // Try and find in a child of a TOC item.
      var found = false;
      MapEntry<EpubNavigationPoint, EpubChapterRef>? foundEntry;
      for (var navPoint in navPointMap.keys) {
        for (var childNavPoint in navPoint.ChildNavigationPoints!) {
          if (checkEqual(childNavPoint, manifestItem)) {
            final subChapter = navigationPointToChapter(
              bookRef,
              childNavPoint,
            );
            if (subChapter != null) {
              // Found in a child of a TOC item. Add chapter.
              final chapter = navPointMap[navPoint]!;
              chapter.SubChapters.add(subChapter);
              found = true;
              foundEntry = MapEntry(childNavPoint, subChapter);
              lastChapter = subChapter;
              break;
            }
          }
        }
        if (found) {
          break;
        }
      }
      if (found) {
        navPointMap.addEntries([foundEntry!]);
        continue;
      }
      // Not found in TOC. Add chapter as OtherFragment.
      final point = EpubNavigationPoint();
      point.Content = EpubNavigationContent();
      point.Content!.Source = manifestItem.Href;
      point.Id = manifestItem.Id;
      point.NavigationLabels = <EpubNavigationLabel>[];
      point.NavigationLabels!.add(EpubNavigationLabel()
        ..Text = lastChapter != null ? 'Untitled Chapter' : 'Begining');
      point.ChildNavigationPoints = <EpubNavigationPoint>[];
      final chapterFragment = navigationPointToChapter(
        bookRef,
        point,
      );
      if (lastChapter != null && chapterFragment != null) {
        lastChapter.OtherChapterFragments.add(
            chapterFragment.epubTextContentFileRef);
      } else if (chapterFragment != null) {
        result.add(chapterFragment);
        lastChapter = chapterFragment;
      }
    }
    return result;
  }

  static EpubChapterRef? navigationPointToChapter(
    EpubBookRef bookRef,
    EpubNavigationPoint navigationPoint,
  ) {
    String contentFileName;
    String? anchor;
    if (navigationPoint.Content?.Source == null) {
      return null;
    }
    Tuple2<String, String?> splitResult =
        splitNavPointSource(navigationPoint.Content!.Source!);
    contentFileName = decodeFileName(splitResult.item1);
    anchor = splitResult.item2;
    EpubTextContentFileRef? htmlContentFileRef;
    if (!bookRef.Content!.Html!.containsKey(contentFileName)) {
      throw Exception(
          'Incorrect EPUB manifest: item with href = \"$contentFileName\" is missing.');
    }

    htmlContentFileRef = bookRef.Content!.Html![contentFileName];
    if (htmlContentFileRef == null) {
      return null;
    }
    var chapterRef = EpubChapterRef(htmlContentFileRef);
    chapterRef.ContentFileName = contentFileName;
    chapterRef.Anchor = anchor;
    chapterRef.Title = navigationPoint.NavigationLabels!.first.Text;
    return chapterRef;
  }

  static Tuple2<String, String?> splitNavPointSource(String source) {
    var contentSourceAnchorCharIndex = source.indexOf('#');
    if (contentSourceAnchorCharIndex == -1) {
      return Tuple2(source, null);
    } else {
      return Tuple2(source.substring(0, contentSourceAnchorCharIndex),
          source.substring(contentSourceAnchorCharIndex + 1));
    }
  }

  static bool checkEqual(EpubNavigationPoint point, EpubManifestItem item) {
    return getContentFileSource(point.Content!.Source!)
            .split('/')
            .last
            .toLowerCase() ==
        item.Href!.split('/').last.toLowerCase();
  }

  static String getContentFileSource(String source) {
    return splitNavPointSource(source).item1;
  }
}
