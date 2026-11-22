import 'package:flutter/services.dart';

/// Native macOS window services, handled in MainFlutterWindow.swift.
const _channel = MethodChannel('json_better_editor/window');

/// Sets the window title. No-op where the native side is absent, such as
/// widget tests.
Future<void> setWindowTitle(String title) async {
  try {
    await _channel.invokeMethod<void>('setTitle', title);
  } on MissingPluginException {
    // No native handler registered.
  }
}

/// Shows the macOS open panel limited to .json files, as a sheet on the
/// window. Returns the chosen path, or null if the user cancelled.
Future<String?> showOpenJsonPanel() =>
    _channel.invokeMethod<String>('openJsonFile');
