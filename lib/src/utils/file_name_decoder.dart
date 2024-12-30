String decodeFileName(String incomingFileName) {
  try {
    return Uri.decodeFull(incomingFileName);
  } catch (e) {
    return incomingFileName;
  }
}
