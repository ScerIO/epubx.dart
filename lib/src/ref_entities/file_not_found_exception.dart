class FileNotFoundException implements Exception {
  final String message;

  FileNotFoundException(this.message);

  @override
  String toString() {
    return message;
  }
}
