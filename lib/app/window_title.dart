import 'package:flutter/services.dart';

const _channel = MethodChannel('json_better_editor/window');

/// Sets the native macOS window title (handled in MainFlutterWindow.swift).
Future<void> setWindowTitle(String title) =>
    _channel.invokeMethod<void>('setTitle', title);
