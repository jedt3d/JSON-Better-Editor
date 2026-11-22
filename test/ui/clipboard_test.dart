import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/l10n/app_localizations.dart';
import 'package:json_better_editor/ui/file_access.dart';
import 'package:json_better_editor/ui/main_window.dart';
import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

import 'editor_support.dart';

const windowChannel = MethodChannel('json_better_editor/window');

void main() {
  String? clipboard;

  setUp(() {
    clipboard = null;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      switch (call.method) {
        case 'Clipboard.setData':
          clipboard = (call.arguments as Map)['text'] as String?;
        case 'Clipboard.getData':
          return {'text': clipboard};
        case 'Clipboard.hasStrings':
          return {'value': clipboard != null};
      }
      return null;
    });
    messenger.setMockMethodCallHandler(windowChannel, (_) async => null);
  });

  Future<CodeLineEditingController> openWithSelection(
    WidgetTester tester,
    CodeLineSelection selection,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainWindow(
          pickJsonFile: () async =>
              const PickedFile(path: '/d/a.json', text: '{"a": [1, 2]}'),
        ),
      ),
    );
    await pressCmd(tester, LogicalKeyboardKey.keyO);
    final controller = editorController(tester)..selection = selection;
    await tester.pumpAndSettle();
    return controller;
  }

  /// "[1, 2]" in '{"a": [1, 2]}'.
  const array = CodeLineSelection(
    baseIndex: 0,
    baseOffset: 6,
    extentIndex: 0,
    extentOffset: 12,
  );

  Future<void> editMenu(WidgetTester tester, String action) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      windowChannel.name,
      windowChannel.codec.encodeMethodCall(MethodCall('edit', action)),
      (_) {},
    );
    await tester.pumpAndSettle();
  }

  group('keyboard', () {
    testWidgets('Cmd+C copies the selection as plain text', (tester) async {
      final controller = await openWithSelection(tester, array);
      await pressCmd(tester, LogicalKeyboardKey.keyC);
      expect(clipboard, '[1, 2]');
      expect(controller.text, '{"a": [1, 2]}');
    }, variant: macOS);

    testWidgets('Cmd+X cuts the selection', (tester) async {
      final controller = await openWithSelection(tester, array);
      await pressCmd(tester, LogicalKeyboardKey.keyX);
      expect(clipboard, '[1, 2]');
      expect(controller.text, '{"a": }');
    }, variant: macOS);

    testWidgets('Cmd+V replaces the selection; Cmd+Z undoes the paste', (
      tester,
    ) async {
      clipboard = 'null';
      final controller = await openWithSelection(tester, array);
      await pressCmd(tester, LogicalKeyboardKey.keyV);
      expect(controller.text, '{"a": null}');
      await pressCmd(tester, LogicalKeyboardKey.keyZ);
      expect(controller.text, '{"a": [1, 2]}');
    }, variant: macOS);
  });

  group('Edit menu', () {
    testWidgets('Copy, Cut and Paste act on the Text pane', (tester) async {
      final controller = await openWithSelection(tester, array);
      await editMenu(tester, 'copy');
      expect(clipboard, '[1, 2]');
      await editMenu(tester, 'cut');
      expect(controller.text, '{"a": }');
      await editMenu(tester, 'paste');
      expect(controller.text, '{"a": [1, 2]}');
    }, variant: macOS);

    testWidgets('Select All, Undo and Redo', (tester) async {
      final controller = await openWithSelection(tester, array);
      await editMenu(tester, 'selectAll');
      expect(controller.selectedText, '{"a": [1, 2]}');
      await editMenu(tester, 'cut');
      expect(controller.text, '');
      await editMenu(tester, 'undo');
      expect(controller.text, '{"a": [1, 2]}');
      await editMenu(tester, 'redo');
      expect(controller.text, '');
    }, variant: macOS);
  });
}
