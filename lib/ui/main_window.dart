import 'package:material_ui/material_ui.dart';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../app/native_window.dart';
import '../document/json_document.dart';
import '../l10n/app_localizations.dart';
import 'file_access.dart';

/// Main window: toolbar on top, content area below.
class MainWindow extends StatefulWidget {
  const MainWindow({
    super.key,
    this.pickJsonFile = pickJsonFileFromDisk,
    this.chooseSavePath = chooseSavePathOnDisk,
    this.writeTextFile = writeTextFileOnDisk,
  });

  final PickJsonFile pickJsonFile;
  final ChooseSavePath chooseSavePath;
  final WriteTextFile writeTextFile;

  @override
  State<MainWindow> createState() => _MainWindowState();
}

/// The file currently shown: its text as read, and the parsed model that
/// Save (#9) and the panes (Phase 2/3) build on.
class _OpenFile {
  const _OpenFile(this.file, this.document);

  final PickedFile file;
  final JsonDocument document;
}

class _MainWindowState extends State<MainWindow> {
  _OpenFile? _open;

  /// True while Open, Save or Save As is running; a second one is ignored.
  bool _busy = false;

  Future<void> _exclusive(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    try {
      await action();
    } finally {
      _busy = false;
    }
  }

  Future<void> _openFile() => _exclusive(_pickAndOpen);

  Future<void> _pickAndOpen() async {
    final l10n = AppLocalizations.of(context)!;
    final PickedFile? picked;
    try {
      picked = await widget.pickJsonFile();
    } on FileAccessException catch (e) {
      if (!mounted) return;
      return _showError(
        e.name.isEmpty ? l10n.openFailed : l10n.openFailedTitle(e.name),
        e.osMessage ?? l10n.fileNotText,
      );
    }
    if (picked == null || !mounted) return;

    switch (parse(picked.text)) {
      case ParseSuccess(:final document):
        setState(() => _open = _OpenFile(picked!, document));
        setWindowTitle(picked.name);
      case ParseFailure(:final error):
        _showError(
          l10n.openFailedTitle(picked.name),
          l10n.invalidJsonPosition(error.line, error.column, error.message),
        );
    }
  }

  /// Cmd+S. Every open document has a file in Phase 1 (New gives the empty
  /// state), so Save always writes to it.
  Future<void> _save() => _exclusive(() async {
    final open = _open;
    if (open != null) await _writeTo(open, open.file.path);
  });

  /// Cmd+Shift+S.
  Future<void> _saveAs() => _exclusive(() async {
    final open = _open;
    if (open == null) return;
    final l10n = AppLocalizations.of(context)!;
    final String? path;
    try {
      path = await widget.chooseSavePath(open.file.name);
    } on FileAccessException catch (e) {
      if (!mounted) return;
      return _showError(l10n.saveFailed, e.osMessage ?? l10n.unknownError);
    }
    if (path != null && mounted) await _writeTo(open, path);
  });

  /// Writes [open]'s pretty-printed document (decision #28) to [path] and
  /// makes [path] the current file.
  Future<void> _writeTo(_OpenFile open, String path) async {
    final l10n = AppLocalizations.of(context)!;
    // Pretty-printed (decision #28), ending with a newline (decision #47).
    final text = '${open.document.toText()}\n';
    try {
      await widget.writeTextFile(path, text);
    } on FileAccessException catch (e) {
      if (!mounted) return;
      return _showError(
        l10n.saveFailedTitle(e.name),
        e.osMessage ?? l10n.unknownError,
      );
    }
    if (!mounted || !identical(_open, open)) return;
    final saved = PickedFile(path: path, text: text);
    setState(() => _open = _OpenFile(saved, open.document));
    setWindowTitle(saved.name);
  }

  void _newDocument() {
    setState(() => _open = null);
    setWindowTitle(AppLocalizations.of(context)!.appTitle);
  }

  Future<void> _showError(String title, String message) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final open = _open;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _save,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true, shift: true):
            _saveAs,
      },
      child: Focus(autofocus: true, child: _scaffold(open, l10n)),
    );
  }

  Widget _scaffold(_OpenFile? open, AppLocalizations l10n) {
    return Scaffold(
      body: Column(
        children: [
          _Toolbar(onNew: _newDocument, onOpen: _openFile),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                open?.file.name ?? l10n.appTitle,
                key: const Key('documentTitle'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: open == null
                ? Center(child: Text(l10n.emptyState))
                : _PlainTextView(text: open.file.text),
          ),
        ],
      ),
    );
  }
}

/// Read-only, scrollable monospace view of the file's text. Phase 2 replaces
/// it with the real Text pane.
class _PlainTextView extends StatelessWidget {
  const _PlainTextView({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: SelectableText(
            text,
            // macOS default monospace font (decisions #17, #29).
            style: const TextStyle(
              fontFamily: 'Menlo',
              fontFamilyFallback: ['Monaco', 'Courier'],
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

/// The toolbar shares the title-bar row with the traffic-light buttons
/// (MainFlutterWindow.swift hides the native title bar). Its empty parts act
/// like a title bar: drag to move the window, double-click to zoom.
class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.onNew, required this.onOpen});

  final VoidCallback onNew;
  final VoidCallback onOpen;

  /// Height of the unified macOS title bar with a toolbar.
  static const height = 52.0;

  /// Room for the traffic-light buttons, which end 80 pt from the left edge.
  static const leadingInset = 88.0;

  /// Width the buttons need; narrower windows cut the toolbar off.
  static const naturalWidth = 610.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final row = Padding(
      padding: const EdgeInsets.only(left: leadingInset, right: 12),
      child: Row(
        children: [
          _ToolbarButton(
            icon: Icons.note_add_outlined,
            tooltip: l10n.toolbarNew,
            onPressed: onNew,
          ),
          _ToolbarButton(
            icon: Icons.folder_open_outlined,
            tooltip: l10n.toolbarOpen,
            onPressed: onOpen,
          ),
          const SizedBox(height: 24, child: VerticalDivider(width: 16)),
          _ToolbarButton(icon: Icons.search, tooltip: l10n.toolbarSearch),
          const Spacer(),
          _ToolbarButton(icon: Icons.notes, tooltip: l10n.toolbarLayoutText),
          _ToolbarButton(
            icon: Icons.account_tree_outlined,
            tooltip: l10n.toolbarLayoutNode,
          ),
          _ToolbarButton(
            icon: Icons.vertical_split_outlined,
            tooltip: l10n.toolbarLayoutSplit,
          ),
          _ToolbarButton(icon: Icons.translate, tooltip: l10n.toolbarLanguage),
          _ToolbarButton(icon: Icons.contrast, tooltip: l10n.toolbarTheme),
          _ToolbarButton(
            icon: Icons.settings_outlined,
            tooltip: l10n.toolbarSettings,
          ),
        ],
      ),
    );
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // Behind the buttons, so it only gets events on empty space.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) => startWindowDrag(),
              onDoubleTap: titleBarDoubleClick,
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) => ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: 0,
                maxWidth: math.max(constraints.maxWidth, naturalWidth),
                child: row,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill-shaped outlined icon button. Without [onPressed] (feature not built
/// yet) it shows a "Coming soon" message.
class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton.outlined(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed:
            onPressed ??
            () => ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.comingSoon),
                ),
              ),
      ),
    );
  }
}
