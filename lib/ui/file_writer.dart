import 'package:flutter/services.dart';

import 'file_access.dart';

/// Saves a whole file safely (#87): the new contents are written to a
/// temporary file first, which then replaces the original in one step. A
/// crash or a full disk mid-save leaves the old file as it was, never a
/// truncated one.
///
/// One implementation per OS:
/// - macOS ([MacFileWriter], built): `FileManager.replaceItemAt`. The temp
///   file goes in a "replacement directory" macOS hands out for this, because
///   the sandbox does not let the app create a sibling file next to the
///   user's file. The original's permissions and other metadata are kept.
/// - Linux (not built): write `<name>.tmp` in the same folder, `fsync`, copy
///   the original's mode bits, then `rename(2)` over the original (atomic on
///   one file system).
/// - Windows (not built): write a temp file in the same folder, then
///   `ReplaceFileW`, which keeps the original's attributes and ACLs.
abstract interface class FileWriter {
  /// Writes [text] as UTF-8 to [path], throwing [FileAccessException] when
  /// it fails; the file at [path] is then unchanged.
  Future<void> write(String path, String text);
}

/// [FileWriter] for macOS; the work is done by `replaceFile` in
/// MainFlutterWindow.swift.
class MacFileWriter implements FileWriter {
  const MacFileWriter();

  static const _channel = MethodChannel('json_better_editor/window');

  @override
  Future<void> write(String path, String text) async {
    try {
      await _channel.invokeMethod<void>('replaceFile', {
        'path': path,
        'text': text,
      });
    } on PlatformException catch (e) {
      throw FileAccessException(path, e.message ?? e.code);
    }
  }
}
