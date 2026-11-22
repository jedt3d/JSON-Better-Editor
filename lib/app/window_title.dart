import 'package:flutter/services.dart';

const _channel = MethodChannel('json_better_editor/window');

/// Sets the native macOS window title (handled in MainFlutterWindow.swift).
/// No-op where the native side is absent, such as widget tests.
Future<void> setWindowTitle(String title) async {
  try {
    await _channel.invokeMethod<void>('setTitle', title);
  } on MissingPluginException {
    // No native handler registered.
  }
}
