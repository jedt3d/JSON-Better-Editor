import 'dart:io';

import '../app/native_window.dart';

/// A .json file chosen by the user, read as UTF-8 text.
class PickedFile {
  const PickedFile({required this.path, required this.text});

  final String path;
  final String text;

  String get name => path.split('/').last;
}

/// Reading the chosen file failed. [osMessage] is null when the file is not
/// UTF-8 text.
class FileAccessException implements Exception {
  const FileAccessException(this.path, [this.osMessage]);

  final String path;
  final String? osMessage;

  String get name => path.split('/').last;
}

/// Asks the user for a .json file and reads it. Null if cancelled.
/// Injected into the UI so tests need no real dialog or disk.
typedef PickJsonFile = Future<PickedFile?> Function();

Future<PickedFile?> pickJsonFileFromDisk() async {
  final path = await showOpenJsonPanel();
  if (path == null) return null;
  try {
    return PickedFile(path: path, text: await File(path).readAsString());
  } on FileSystemException catch (e) {
    throw FileAccessException(path, e.osError?.message ?? e.message);
  } on FormatException {
    throw FileAccessException(path);
  }
}
