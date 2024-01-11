import 'dart:math';

import 'package:collection/collection.dart';
import 'package:epubx/epubx.dart';
import 'package:epubx/example/epub_cfi_reader.dart';
import 'package:epubx/example/paragraph.dart';
import 'package:epubx/example/parse_paragraph_result.dart';
import 'package:epubx/example/utils.dart';

import 'package:html/dom.dart' as dom;

export 'package:epubx/epubx.dart' hide Image;

class EpubParser {
  int wordsBefore = 0;

  static List<EpubChapter> getAllSubChapters(
    EpubChapter chapter, {
    bool includeChapter = true,
  }) {
    final list = [if (includeChapter) chapter];
    if (chapter.SubChapters?.isNotEmpty == true) {
      for (var i = 0; i < chapter.SubChapters!.length; i++) {
        final subChapter = chapter.SubChapters![i];
        list.addAll(getAllSubChapters(subChapter));
      }
    }
    return list;
  }

  static List<EpubChapter> parseChapters(EpubBook epubBook) =>
      epubBook.getRealChaptersOrCreated().fold<List<EpubChapter>>(
        [],
        (acc, next) {
          acc.addAll(getAllSubChapters(next));

          return acc;
        },
      );

  Map<String, String> hrefMap = {};

  static List<dom.Element> convertDocumentToElements(dom.Document document) =>
      document.getElementsByTagName('body').first.children;

  List<dom.Element> _removeAllDiv(List<dom.Element> elements) {
    final result = <dom.Element>[];

    for (final node in elements) {
      setNodeId(node, true);
      setNodeIds(node);

      if (node.localName == 'div' && node.children.length > 1) {
        result.addAll(_removeAllDiv(node.children));
      } else {
        result.add(node);
      }
    }

    return result;
  }

  void setNodeIds(dom.Element node) {
    for (var element in node.children) {
      setNodeId(element);
    }
  }

  void setNodeId(dom.Element node, [bool saveHref = false]) {
    var newId =
        node.id.isEmpty ? node.querySelector('[id]')?.id ?? '' : node.id;
    if (newId.isNotEmpty) {
      final ids = node.querySelectorAll('[id]').map((e) => e.id);

      node.id = newId;
      if (saveHref) {
        for (var element in ids) {
          if (element.isNotEmpty) {
            hrefMap[element] = newId;
          }
        }
      }
    }
    setNodeIds(node);
  }

  ParseParagraphsResult parseParagraphs(
    List<EpubChapter> chapters,
  ) {
    int? hashcode = 0;
    final chapterIndexes = <int>[];
    wordsBefore = 0;
    final paragraphs = chapters.fold<List<Paragraph>>(
      [],
      (acc, next) {
        var elmList = <dom.Element>[];
        if (hashcode != next.hashCode) {
          hashcode = next.hashCode;
          final document = EpubCfiReader().chapterDocument(next.HtmlContent);
          if (document != null) {
            final result = convertDocumentToElements(document);
            elmList = _removeAllDiv(result);
          }
        }

        if (next.Anchor == null) {
          // last element from document index as chapter index
          chapterIndexes.add(acc.length);
          acc.addAll(
            elmList.map(
              (element) => _countParagraphAndWordsCount(
                element: element,
                chapterIndex: chapterIndexes.length - 1,
              ),
            ),
          );
          return acc;
        } else {
          final index = elmList.indexWhere(
            (elm) => elm.outerHtml.contains(
              'id="${next.Anchor}"',
            ),
          );
          if (index == -1) {
            chapterIndexes.add(acc.length);
            acc.addAll(
              elmList.map(
                (element) => _countParagraphAndWordsCount(
                  element: element,
                  chapterIndex: chapterIndexes.length - 1,
                ),
              ),
            );
            return acc;
          }

          chapterIndexes.add(index + acc.length);
          acc.addAll(
            elmList.mapIndexed(
              (elementIndex, element) => _countParagraphAndWordsCount(
                element: element,
                chapterIndex: elementIndex < index
                    ? max(chapterIndexes.length - 2, 0)
                    : chapterIndexes.length - 1,
              ),
            ),
          );
          return acc;
        }
      },
    );

    return ParseParagraphsResult(paragraphs, chapterIndexes, hrefMap);
  }

  Paragraph _countParagraphAndWordsCount({
    required dom.Element element,
    required int chapterIndex,
  }) {
    final paragraph = Paragraph(
      element: element,
      chapterIndex: chapterIndex,
      percent: 0,
      symbolsCount: countSymbolsInElement(element),
      wordsBefore: wordsBefore,
    );
    wordsBefore += paragraph.symbolsCount;
    return paragraph;
  }
}

extension EpubBookExtension on EpubBook {
  List<EpubChapter> getRealChaptersOrCreated() {
    var chapters = <EpubChapter>[...(Chapters ?? [])];
    if (chapters.isEmpty) {
      chapters = Content?.Html?.values
              .mapIndexed((i, e) => EpubChapter()
                ..HtmlContent = e.Content
                ..ContentFileName = e.FileName
                ..Title = 'Глава ${i + 1}')
              .toList() ??
          [];
    }
    chapters.removeWhere((element) =>
        element.ContentFileName?.toLowerCase().startsWith('cover') ?? false);
    return chapters;
  }
}
