import 'dart:io';

import 'package:flutter/services.dart';

import '../app/native_window.dart';

/// A .json file chosen by the user, read as UTF-8 text.
class PickedFile {
  const PickedFile({required this.path, required this.text});

  final String path;
  final String text;

  String get name => path.split('/').last;
}

/// Picking or reading the file failed. [osMessage] is null when the file is
/// not UTF-8 text; [path] is empty when the open panel itself failed.
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
  final path = await _panel(showOpenJsonPanel);
  if (path == null) return null;
  try {
    return PickedFile(path: path, text: await File(path).readAsString());
  } on FileSystemException catch (e) {
    throw FileAccessException(path, e.osError?.message ?? e.message);
  } on FormatException {
    throw FileAccessException(path);
  }
}

/// Asks the user where to save, pre-filled with [suggestedName]. Null if
/// cancelled.
typedef ChooseSavePath = Future<String?> Function(String suggestedName);

/// Writes [text] to [path], throwing [FileAccessException] on failure.
typedef WriteTextFile = Future<void> Function(String path, String text);

Future<String?> chooseSavePathOnDisk(String suggestedName) =>
    _panel(() => showSaveJsonPanel(suggestedName));

// ponytail: writes in place (the sandbox only grants the chosen file, not a
// sibling temp file), so a crash mid-write can truncate it. Revisit with
// NSFileCoordinator / replaceItemAt if that matters.
Future<void> writeTextFileOnDisk(String path, String text) async {
  try {
    await File(path).writeAsString(text, flush: true);
  } on FileSystemException catch (e) {
    throw FileAccessException(path, e.osError?.message ?? e.message);
  }
}

/// Runs a native panel call; channel failures become [FileAccessException]
/// with an empty path.
Future<String?> _panel(Future<String?> Function() show) async {
  try {
    return await show();
  } on PlatformException catch (e) {
    throw FileAccessException('', e.message ?? e.code);
  } on MissingPluginException catch (e) {
    throw FileAccessException('', e.message);
  }
}
