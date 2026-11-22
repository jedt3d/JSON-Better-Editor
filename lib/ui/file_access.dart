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

/// Picking, reading or writing a file failed. [path] is empty when the
/// open or save panel itself failed. [osMessage] is null when there is no
/// OS message (when reading, that means the file is not UTF-8 text).
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
  return path == null ? null : readJsonFileFromDisk(path);
}

/// Reads the file at [path] (chosen in Finder or the open panel) as UTF-8.
/// Injected into the UI so tests need no disk.
typedef ReadJsonFile = Future<PickedFile> Function(String path);

Future<PickedFile> readJsonFileFromDisk(String path) async {
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

// ponytail: writes in place, because the sandbox grants only the chosen file
// and not a sibling temp file to rename over it. A failed write puts the old
// contents back, but a crash mid-write can still truncate the file
// (decision #42). Upgrade path: native NSFileCoordinator / replaceItemAt.
Future<void> writeTextFileOnDisk(String path, String text) async {
  final file = File(path);
  List<int>? previous;
  try {
    if (await file.exists()) previous = await file.readAsBytes();
    await file.writeAsString(text, flush: true);
  } on FileSystemException catch (e) {
    if (previous != null) {
      try {
        await file.writeAsBytes(previous, flush: true);
      } on FileSystemException {
        // Nothing more we can do; the error below is still reported.
      }
    }
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
