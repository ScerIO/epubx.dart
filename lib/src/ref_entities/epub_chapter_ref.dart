import 'dart:async';

import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import 'epub_text_content_file_ref.dart';

class EpubChapterRef {
  EpubTextContentFileRef? epubTextContentFileRef;

  String? Title;
  String? ContentFileName;
  String? Anchor;
  List<EpubChapterRef>? SubChapters;

  EpubChapterRef(EpubTextContentFileRef? epubTextContentFileRef) {
    this.epubTextContentFileRef = epubTextContentFileRef;
  }

  @override
  int get hashCode {
    var objects = [
      Title.hashCode,
      ContentFileName.hashCode,
      Anchor.hashCode,
      epubTextContentFileRef.hashCode,
      ...SubChapters?.map((subChapter) => subChapter.hashCode) ?? [0],
    ];
    return hashObjects(objects);
  }

  @override
  bool operator ==(other) {
    if (!(other is EpubChapterRef)) {
      return false;
    }
    return Title == other.Title &&
        ContentFileName == other.ContentFileName &&
        Anchor == other.Anchor &&
        epubTextContentFileRef == other.epubTextContentFileRef &&
        collections.listsEqual(SubChapters, other.SubChapters);
  }

  Future<String> readHtmlContent() async {
    final content = await epubTextContentFileRef!.readContentAsText();
    final normalized = normalizeHtml(content);
    return normalized;
  }

  String normalizeHtml(String html){
    final replacedTrailings = _replaceTagsWithTrailingSolidus(html);
    final replacedSpecChars = _replaceSpecialCharactersInHtml(replacedTrailings);
    return replacedSpecChars;
  }

  String _replaceSpecialCharactersInHtml(String html){
    var replacements = {
      '&#160;': '&nbsp;', // non-breaking space
      '&#161;': '&iexcl;', // inverted exclamation mark
      '&#162;': '&cent;', // cent sign
      '&#163;': '&pound;', // pound sign
      '&#164;': '&curren;', // currency sign
      '&#165;': '&yen;', // yen sign
      '&#166;': '&brvbar;', // broken bar
      '&#167;': '&sect;', // section sign
      '&#168;': '&uml;', // diaeresis
      '&#169;': '&copy;', // copyright sign
      '&#170;': '&ordf;', // feminine ordinal indicator
      '&#171;': '&laquo;', // left-pointing double angle quotation mark
      '&#172;': '&not;', // not sign
      '&#173;': '&shy;', // soft hyphen
      '&#174;': '&reg;', // registered sign
      '&#175;': '&macr;', // macron
      '&#176;': '&deg;', // degree sign
      '&#177;': '&plusmn;', // plus-minus sign
      '&#178;': '&sup2;', // superscript two
      '&#179;': '&sup3;', // superscript three
      '&#180;': '&acute;', // acute accent
      '&#181;': '&micro;', // micro sign
      '&#182;': '&para;', // pilcrow sign
      '&#183;': '&middot;', // middle dot
      '&#184;': '&cedil;', // cedilla
      '&#185;': '&sup1;', // superscript one
      '&#186;': '&ordm;', // masculine ordinal indicator
      '&#187;': '&raquo;', // right-pointing double angle quotation mark
      '&#188;': '&frac14;', // vulgar fraction one quarter
      '&#189;': '&frac12;', // vulgar fraction one half
      '&#190;': '&frac34;', // vulgar fraction three quarters
      '&#191;': '&iquest;', // inverted question mark
      '&#192;': '&Agrave;', // Latin capital letter A with grave
      '&#193;': '&Aacute;', // Latin capital letter A with acute
      '&#194;': '&Acirc;', // Latin capital letter A with circumflex
      '&#195;': '&Atilde;', // Latin capital letter A with tilde
      '&#196;': '&Auml;', // Latin capital letter A with diaeresis
      '&#197;': '&Aring;', // Latin capital letter A with ring above
      '&#198;': '&AElig;', // Latin capital letter AE
      '&#199;': '&Ccedil;', // Latin capital letter C with cedilla
      '&#200;': '&Egrave;', // Latin capital letter E with grave
      '&#201;': '&Eacute;', // Latin capital letter E with acute
      '&#202;': '&Ecirc;', // Latin capital letter E with circumflex
      '&#203;': '&Euml;', // Latin capital letter E with diaeresis
      '&#204;': '&Igrave;', // Latin capital letter I with grave
      '&#205;': '&Iacute;', // Latin capital letter I with acute
      '&#206;': '&Icirc;', // Latin capital letter I with circumflex
      '&#207;': '&Iuml;', // Latin capital letter I with diaeresis
      '&#208;': '&ETH;', // Latin capital letter Eth
      '&#209;': '&Ntilde;', // Latin capital letter N with tilde
      '&#210;': '&Ograve;', // Latin capital letter O with grave
      '&#211;': '&Oacute;', // Latin capital letter O with acute
      '&#212;': '&Ocirc;', // Latin capital letter O with circumflex
      '&#213;': '&Otilde;', // Latin capital letter O with tilde
      '&#214;': '&Ouml;', // Latin capital letter O with diaeresis
      '&#215;': '&times;', // multiplication sign
      '&#216;': '&Oslash;', // Latin capital letter O with stroke
      '&#217;': '&Ugrave;', // Latin capital letter U with grave
      '&#218;': '&Uacute;', // Latin capital letter U with acute
      '&#219;': '&Ucirc;', // Latin capital letter U with circumflex
      '&#220;': '&Uuml;', // Latin capital letter U with diaeresis
      '&#221;': '&Yacute;', // Latin capital letter Y with acute
      '&#222;': '&THORN;', // Latin capital letter Thorn
      '&#223;': '&szlig;', // Latin small letter sharp s
      '&#224;': '&agrave;', // Latin small letter a with grave
      '&#225;': '&aacute;', // Latin small letter a with acute
      '&#226;': '&acirc;', // Latin small letter a with circumflex
      '&#227;': '&atilde;', // Latin small letter a with tilde
      '&#228;': '&auml;', // Latin small letter a with diaeresis
      '&#229;': '&aring;', // Latin small letter a with ring above
      '&#230;': '&aelig;', // Latin lowercase ligature ae
      '&#231;': '&ccedil;', // Latin small letter c with cedilla
      '&#232;': '&egrave;', // Latin small letter e with grave
      '&#233;': '&eacute;', // Latin small letter e with acute
      '&#234;': '&ecirc;', // Latin small letter e with circumflex
      '&#235;': '&euml;', // Latin small letter e with diaeresis
      '&#236;': '&igrave;', // Latin small letter i with grave
      '&#237;': '&iacute;', // Latin small letter i with acute
      '&#238;': '&icirc;', // Latin small letter i with circumflex
      '&#239;': '&iuml;', // Latin small letter i with diaeresis
      '&#240;': '&eth;', // Latin small letter eth
      '&#241;': '&ntilde;', // Latin small letter n with tilde
      '&#242;': '&ograve;', // Latin small letter o with grave
      '&#243;': '&oacute;', // Latin small letter o with acute
      '&#244;': '&ocirc;', // Latin small letter o with circumflex
      '&#245;': '&otilde;', // Latin small letter o with tilde
      '&#246;': '&ouml;', // Latin small letter o with diaeresis
      '&#247;': '&divide;', // division sign
      '&#248;': '&oslash;', // Latin small letter o with stroke
      '&#249;': '&ugrave;', // Latin small letter u with grave
      '&#250;': '&uacute;', // Latin small letter u with acute
      '&#251;': '&ucirc;', // Latin small letter u with circumflex
      '&#252;': '&uuml;', // Latin small letter u with diaeresis
      '&#253;': '&yacute;', // Latin small letter y with acute
      '&#254;': '&thorn;', // Latin small letter thorn
      '&#255;': '&yuml;',
    };

    for (var entry in replacements.entries) {
      html = html.replaceAll(entry.key, entry.value);
    }

    return html;
  }

  String _replaceTagsWithTrailingSolidus(String htmlContent) {
    // Define a regular expression to match all tags with trailing solidus
    final tagWithSolidusRegex = RegExp(r'<(\w+)([^>]*)/>');

    // Use the replaceAll method to replace all occurrences of the matched pattern
    var modifiedHtml =
        htmlContent.replaceAllMapped(tagWithSolidusRegex, (match) {
      // Extract the tag name and attributes from the original match
      var tagName = match.group(1) ?? '';
      var attributes = match.group(2) ?? '';

      // Replace the self-closing syntax with the standard opening and closing tag
      return '<$tagName$attributes></$tagName>';
    });

    return modifiedHtml;
  }

  @override
  String toString() {
    return 'Title: $Title, Subchapter count: ${SubChapters!.length}';
  }
}
