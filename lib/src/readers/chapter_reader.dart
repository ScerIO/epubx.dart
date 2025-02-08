import 'package:epubx/epubx.dart';
import 'package:epubx/src/utils/file_name_decoder.dart';

import '../ref_entities/epub_text_content_file_ref.dart';

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
                element!.Content!.Source!.split('/').last.toLowerCase() ==
                manifestItem.Href!.split('/').last.toLowerCase(),
            orElse: () => null,
          );
      if (navPoint != null) {
        lastTopLevelChapter = navigationPointToChapter(
          bookRef,
          navPoint,
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
          if (childNavPoint.Content!.Source!.split('/').last.toLowerCase() ==
              manifestItem.Href!.split('/').last.toLowerCase()) {
            final subChapter = navigationPointToChapter(
              bookRef,
              childNavPoint,
            );
            if (subChapter != null) {
              lastTopLevelChapter!.SubChapters.add(subChapter);
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
      final chapterFragment = navigationPointToChapter(
        bookRef,
        point,
      );
      if (lastTopLevelChapter != null && chapterFragment != null) {
        lastTopLevelChapter.OtherChapterFragments.add(
            chapterFragment.epubTextContentFileRef);
      } else if (chapterFragment != null) {
        result.add(chapterFragment);
        lastTopLevelChapter = chapterFragment;
      }
    }
    return result;
  }

  static EpubChapterRef? navigationPointToChapter(
    EpubBookRef bookRef,
    EpubNavigationPoint navigationPoint,
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
    if (htmlContentFileRef == null) {
      return null;
    }
    var chapterRef = EpubChapterRef(htmlContentFileRef);
    chapterRef.ContentFileName = contentFileName;
    chapterRef.Anchor = anchor;
    chapterRef.Title = navigationPoint.NavigationLabels!.first.Text;
    return chapterRef;
  }
}
