extension StringExtension on String {
  bool isFileHtml() => endsWith('html') || endsWith('xml');

  bool isBlank() => trim().isEmpty;

  bool isNotBlank() => !isBlank();
}
