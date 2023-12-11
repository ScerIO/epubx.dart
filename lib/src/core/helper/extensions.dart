extension StringExtension on String {
  bool isFileHtml() => endsWith('html') || endsWith('xml');
}
