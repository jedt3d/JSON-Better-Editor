import 'package:flutter/services.dart';

/// Native macOS window services, handled in MainFlutterWindow.swift.
const _channel = MethodChannel('json_better_editor/window');

/// Calls [method] for its effect only. No-op where the native side is
/// absent, such as widget tests.
Future<void> _fire(String method, [Object? arguments]) async {
  try {
    await _channel.invokeMethod<void>(method, arguments);
  } on MissingPluginException {
    // No native handler registered.
  }
}

/// Sets the window title (Window menu, Mission Control).
Future<void> setWindowTitle(String title) => _fire('setTitle', title);

/// Starts moving the window with the mouse, as a drag on a title bar does.
/// Call it when a drag starts on an empty part of the toolbar.
Future<void> startWindowDrag() => _fire('startWindowDrag');

/// Does what double-clicking a title bar does in System Settings
/// (zoom by default, or minimize, or nothing).
Future<void> titleBarDoubleClick() => _fire('titleBarDoubleClick');

/// Shows the macOS open panel limited to .json files, as a sheet on the
/// window. Returns the chosen path, or null if the user cancelled.
Future<String?> showOpenJsonPanel() =>
    _channel.invokeMethod<String>('openJsonFile');

/// Shows the macOS save panel for a .json file, as a sheet on the window,
/// pre-filled with [suggestedName]. Returns the chosen path, or null if
/// the user cancelled.
Future<String?> showSaveJsonPanel(String suggestedName) =>
    _channel.invokeMethod<String>('saveJsonFile', suggestedName);
