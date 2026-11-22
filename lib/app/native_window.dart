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

/// Shows the document as edited: the dot in the window's close button.
Future<void> setDocumentEdited(bool edited) => _fire('setEdited', edited);

/// Requests from the native side, answered by [handler] (null removes it):
/// - `confirmClose`: Close (red button, File › Close, Cmd+W) and Quit ask
///   first; answer true when the window may close or the app may quit.
/// - `menu` with `new`, `open`, `save`, `saveAs` (File menu), `wordWrap`
///   (View menu), `validate`, `format`, `minify`, `goToLine` (Edit menu),
///   `closeDocument` (the window was closed and hidden, #93), `clearRecent`
///   (File › Open Recent › Clear Menu).
/// - `openRecent` with a path: a File › Open Recent entry (#92)., `find`,
///   `findNext` or `findPrevious` (Edit › Find), `statusBar` (View menu,
///   #98).
/// - `openPath` with a file path: a .json opened from Finder (#32).
/// - `edit` with `undo`, `redo`, `cut`, `copy`, `paste` or `selectAll`: an
///   Edit menu item (#38, #43).
void onNativeRequest(
  Future<Object?> Function(String method, Object? arguments)? handler,
) {
  _channel.setMethodCallHandler(
    handler == null ? null : (call) => handler(call.method, call.arguments),
  );
}

/// Paths of .json files Finder asked the app to open before Dart was ready
/// (for example the file that launched the app). Empty when there are none.
Future<List<String>> takePendingOpenPaths() async {
  try {
    final paths = await _channel.invokeListMethod<String>(
      'takePendingOpenPaths',
    );
    return paths ?? const [];
  } on MissingPluginException {
    return const [];
  }
}

/// Shows the View › Word Wrap checkmark.
Future<void> setWordWrapChecked(bool on) => _fire('setWordWrapChecked', on);

/// File › Open Recent (#92). The list of paths is kept by the app; macOS
/// keeps a security-scoped bookmark per file so it can be opened again
/// after a restart (the sandbox otherwise forgets the user's permission).
Future<List<String>> loadRecentFiles() async {
  try {
    return await _channel.invokeListMethod<String>('loadRecentFiles') ??
        const [];
  } on MissingPluginException {
    return const [];
  }
}

/// Stores [paths] (newest first) and rebuilds File › Open Recent.
Future<void> saveRecentFiles(List<String> paths) =>
    _fire('saveRecentFiles', paths);

/// Asks macOS for a bookmark to [path] while the app may read it (just
/// opened or saved).
Future<void> rememberRecentFile(String path) => _fire('rememberRecent', path);

/// Regains access to a recent file through its bookmark. Returns the
/// file's current path, or null when it is missing.
Future<String?> accessRecentFile(String path) async {
  try {
    return await _channel.invokeMethod<String>('accessRecent', path);
  } on MissingPluginException {
    return path;
  }
}

/// Sets the View menu item to "Hide Status Bar" or "Show Status Bar".
Future<void> setStatusBarShown(bool shown) => _fire('setStatusBarShown', shown);
