import 'package:flutter/material.dart';
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
    final text = open.document.toText();
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

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.onNew, required this.onOpen});

  final VoidCallback onNew;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
