import 'dart:math';

import 'package:epubx/example/paragraph.dart';
import 'package:html/dom.dart';

Duration countReadDurationOfParagraph(Paragraph paragraph) {
  final symbolsInParagraph = paragraph.symbolsCount;
  const symbolsPerSecond = 25;
  final normalReadSeconds = symbolsInParagraph / symbolsPerSecond;
  const coef = 0.1;
  final coefReadSeconds = normalReadSeconds * coef;
  final coedReadMilliseconds = coefReadSeconds * 1000;
  return Duration(milliseconds: coedReadMilliseconds.round());
}

int countSymbolsInElement(Element element) {
  return getSymbolsCountsInNodeList(element.nodes);
}

double countUserProgress(
  List<Paragraph> paragraphs, {
  required int chapterNumber,
  required int paragraphNumber,
  required double lastPercent,
}) {
  var allSymbols = 0;
  var readSymbols = 0.0;
  for (var i = 0; i < paragraphs.length; i++) {
    final paragraph = paragraphs[i];
    allSymbols += paragraph.symbolsCount;
    if (paragraph.chapterIndex < chapterNumber) {
      readSymbols += paragraph.symbolsCount;
    } else if (paragraph.chapterIndex == chapterNumber) {
      if (i < paragraphNumber) {
        readSymbols += paragraph.symbolsCount;
      } else if (i == paragraphNumber) {
        readSymbols += paragraph.symbolsCount * lastPercent;
      }
    }
  }
  final readPercent = readSymbols / allSymbols;
  return readPercent;
}

double countRealProgress(List<Paragraph> paragraphs) {
  var allSymbols = 0;
  var readSymbols = 0.0;
  for (var i = 0; i < paragraphs.length; i++) {
    final paragraph = paragraphs[i];
    allSymbols += paragraph.symbolsCount;

    readSymbols += paragraph.symbolsCount * paragraph.percent;
  }

  final readPercent = readSymbols / allSymbols;
  return max(readPercent, 0.001);
}

int getSymbolsCountsInNode(Node node) {
  var symbolsCount = node.text?.trim().replaceAll(' ', '').length ?? 0;
  if (node.nodes.isNotEmpty) {
    symbolsCount += getSymbolsCountsInNodeList(node.nodes);
  }
  return symbolsCount;
}

int getSymbolsCountsInNodeList(NodeList nodeList) {
  var symbolsCount = 0;
  for (var i = 0; i < nodeList.length; i++) {
    symbolsCount += getSymbolsCountsInNode(nodeList[i]);
  }
  return symbolsCount;
}

const smallConversionNumber = 10000.0;
double convertProgressToSmallModel(double progress) =>
    (progress / smallConversionNumber) + 0.8;

double convertSmallModelToProgress(double model) {
  if (model >= 0.75 && model <= 0.85) {
    final converted = (model - 0.8) * smallConversionNumber;
    return converted;
  }

  return model;
}
