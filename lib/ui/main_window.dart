import 'package:material_ui/material_ui.dart';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:re_editor/re_editor.dart';

import '../app/native_window.dart';
import '../document/json_document.dart';
import '../l10n/app_localizations.dart';
import 'file_access.dart';
import 'text_pane.dart';
import 'toolbar_metrics.dart';

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

/// The document currently shown: the file it belongs to (null for a new,
/// never-saved document), and the Text pane's editing controller, which
/// holds the current (possibly edited) text.
class _OpenFile {
  _OpenFile(this.file, this.controller) : savedLines = controller.codeLines;

  final PickedFile? file;
  final CodeLineEditingController controller;

  /// The editor's lines when the document was opened or last saved. re_editor
  /// replaces this object on every edit and puts it back on undo, so the
  /// document is edited exactly when the current lines are another object.
  final CodeLines savedLines;

  bool get edited => !identical(controller.codeLines, savedLines);

  /// The file name, or [untitled] for a new document.
  String name(String untitled) => file?.name ?? untitled;
}

class _MainWindowState extends State<MainWindow> {
  _OpenFile? _open;

  /// True while Open, Save or Save As is running; a second one is ignored.
  bool _busy = false;

  /// Whether the window shows the document as edited (decision #55).
  bool _edited = false;

  /// Replaces the open document, disposing the old editor controller.
  void _setOpen(_OpenFile? open) {
    final old = _open;
    old?.controller.removeListener(_onEdit);
    open?.controller.addListener(_onEdit);
    setState(() => _open = open);
    _onEdit();
    if (old != null && !identical(old.controller, open?.controller)) {
      // After this frame, so the editor no longer listens to it.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => old.controller.dispose(),
      );
    }
  }

  /// Keeps the edited marker (title and close-button dot) up to date.
  void _onEdit() {
    final edited = _open?.edited ?? false;
    if (edited == _edited) return;
    setState(() => _edited = edited);
    setDocumentEdited(edited);
  }

  @override
  void initState() {
    super.initState();
    onCloseRequest(_confirmDiscard);
  }

  @override
  void dispose() {
    onCloseRequest(null);
    _open?.controller.dispose();
    super.dispose();
  }

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

  /// Asks Save / Don't Save / Cancel when the document has unsaved changes
  /// (decision #55). True when it is fine to drop the document: there were
  /// no changes, the user chose Don't Save, or the save succeeded.
  Future<bool> _confirmDiscard() async {
    final open = _open;
    if (open == null || !open.edited) return true;
    final l10n = AppLocalizations.of(context)!;
    final choice = await showDialog<_UnsavedChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unsavedTitle(open.name(l10n.untitled))),
        content: Text(l10n.unsavedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_UnsavedChoice.discard),
            child: Text(l10n.dontSave),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_UnsavedChoice.cancel),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            autofocus: true, // Default button: Return chooses Save.
            onPressed: () => Navigator.of(context).pop(_UnsavedChoice.save),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (!mounted || !identical(open, _open)) return false;
    switch (choice) {
      case _UnsavedChoice.discard:
        return true;
      case _UnsavedChoice.save:
        final path = open.file?.path;
        return path == null ? _askPathAndWrite(open) : _writeTo(open, path);
      case _UnsavedChoice.cancel || null:
        return false;
    }
  }

  Future<void> _pickAndOpen() async {
    if (!await _confirmDiscard() || !mounted) return;
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
      case ParseSuccess():
        _setOpen(_OpenFile(picked, textPaneController(picked.text)));
        setWindowTitle(picked.name);
      case ParseFailure(:final error):
        _showError(
          l10n.openFailedTitle(picked.name),
          l10n.invalidJsonPosition(error.line, error.column, error.message),
        );
    }
  }

  /// Cmd+S. A document with no file yet behaves like Save As (#29).
  Future<void> _save() => _exclusive(() async {
    final open = _open;
    if (open == null) return;
    final path = open.file?.path;
    await (path == null ? _askPathAndWrite(open) : _writeTo(open, path));
  });

  /// Cmd+Shift+S.
  Future<void> _saveAs() => _exclusive(() async {
    final open = _open;
    if (open != null) await _askPathAndWrite(open);
  });

  /// Shows the save panel; Cancel leaves everything as it was. True when
  /// the document was written.
  Future<bool> _askPathAndWrite(_OpenFile open) async {
    final l10n = AppLocalizations.of(context)!;
    final String? path;
    try {
      path = await widget.chooseSavePath(open.name(l10n.untitled));
    } on FileAccessException catch (e) {
      if (mounted) {
        await _showError(l10n.saveFailed, e.osMessage ?? l10n.unknownError);
      }
      return false;
    }
    return path != null && mounted && await _writeTo(open, path);
  }

  /// Writes the edited text, pretty-printed (decision #28), to [path] and
  /// makes [path] the current file. Invalid JSON is not written; the error
  /// dialog shows where it is (decision #54). The editor keeps the text as
  /// typed (decision #61). True when the file was written.
  Future<bool> _writeTo(_OpenFile open, String path) async {
    final l10n = AppLocalizations.of(context)!;
    final JsonDocument document;
    switch (parse(open.controller.text)) {
      case ParseSuccess(document: final parsed):
        document = parsed;
      case ParseFailure(:final error):
        await _showError(
          l10n.saveFailedTitle(path.split('/').last),
          l10n.invalidJsonPosition(error.line, error.column, error.message),
        );
        return false;
    }
    // Ending with a newline (decision #47).
    final text = '${document.toText()}\n';
    try {
      await widget.writeTextFile(path, text);
    } on FileAccessException catch (e) {
      if (mounted) {
        await _showError(
          l10n.saveFailedTitle(e.name),
          e.osMessage ?? l10n.unknownError,
        );
      }
      return false;
    }
    if (!mounted || !identical(_open, open)) return true;
    final saved = PickedFile(path: path, text: text);
    // ponytail: the saved state is the lines at the moment Save finished, so
    // typing during a slow write would be counted as saved. Capture the lines
    // before parsing if writes ever become slow enough to matter.
    _setOpen(_OpenFile(saved, open.controller));
    setWindowTitle(saved.name);
    return true;
  }

  /// Cmd+N: a new, never-saved document holding `{}`.
  Future<void> _newDocument() => _exclusive(() async {
    if (!await _confirmDiscard() || !mounted) return;
    final untitled = AppLocalizations.of(context)!.untitled;
    _setOpen(_OpenFile(null, textPaneController('{}')));
    setWindowTitle(untitled);
  });

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
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true):
            _newDocument,
        const SingleActivator(LogicalKeyboardKey.keyO, meta: true): _openFile,
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
                open == null
                    ? l10n.appTitle
                    : _edited
                    ? l10n.editedTitle(open.name(l10n.untitled))
                    : open.name(l10n.untitled),
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
                : TextPane(
                    key: ObjectKey(open.controller),
                    controller: open.controller,
                  ),
          ),
        ],
      ),
    );
  }
}

enum _UnsavedChoice { save, discard, cancel }

/// The toolbar shares the title-bar row with the traffic-light buttons
/// (MainFlutterWindow.swift hides the native title bar). Its empty parts act
/// like a title bar: drag to move the window, double-click to zoom.
class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.onNew, required this.onOpen});

  final VoidCallback onNew;
  final VoidCallback onOpen;

  static const metrics = ToolbarMetrics.macOS;
  static const buttonCount = 9;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final row = Padding(
      padding: EdgeInsets.only(
        left: metrics.leadingInset,
        right: metrics.trailingInset,
      ),
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
          SizedBox(
            height: metrics.buttonSize * 0.6,
            child: VerticalDivider(width: metrics.gap * 2),
          ),
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
      height: metrics.height,
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
                maxWidth: math.max(
                  constraints.maxWidth,
                  metrics.naturalWidth(buttonCount),
                ),
                child: row,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Borderless icon button that shows a rounded fill only on hover and press,
/// like macOS toolbars (decision #50). Without [onPressed] (feature not built
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
    const m = _Toolbar.metrics;
    final colors = Theme.of(context).colorScheme;
    final size = WidgetStatePropertyAll(Size.square(m.buttonSize));
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: m.gap / 2),
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        style: ButtonStyle(
          fixedSize: size,
          minimumSize: size,
          maximumSize: size,
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          iconSize: WidgetStatePropertyAll(m.iconSize),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(m.cornerRadius),
            ),
          ),
          foregroundColor: WidgetStatePropertyAll(colors.onSurfaceVariant),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? colors.onSurface.withValues(alpha: 0.16)
                : states.contains(WidgetState.hovered)
                ? colors.onSurface.withValues(alpha: 0.08)
                : colors.onSurface.withValues(alpha: 0),
          ),
        ),
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
