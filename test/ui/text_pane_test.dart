import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/l10n/app_localizations.dart';
import 'package:json_better_editor/ui/file_access.dart';
import 'package:json_better_editor/ui/main_window.dart';
import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

import 'editor_support.dart';

/// In-memory disk: Open reads [files][openPath], Save writes into [files].
class Disk {
  Disk(this.openPath, String text) : files = {openPath: text};

  final String openPath;
  final Map<String, String> files;

  Future<PickedFile?> pick() async =>
      PickedFile(path: openPath, text: files[openPath]!);

  Future<void> write(String path, String text) async => files[path] = text;
}

Future<void> openApp(WidgetTester tester, Disk disk) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MainWindow(
        pickJsonFile: disk.pick,
        chooseSavePath: (_) async => null,
        writeTextFile: disk.write,
      ),
    ),
  );
  await tester.tap(find.byTooltip('Open'));
  await tester.pumpAndSettle();
  await tester.tap(textEditor);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('typing edits the text at the caret', (tester) async {
    await openApp(tester, Disk('/d/a.json', '[1]'));
    final controller = editorController(tester);
    controller.selection = const CodeLineSelection.collapsed(
      index: 0,
      offset: 2,
    );
    await tester.pump();

    await typeText(tester, ', 2');

    expect(controller.text, '[1, 2]');
  }, variant: macOS);

  testWidgets('Cmd+A selects all and arrow keys move the caret', (
    tester,
  ) async {
    await openApp(tester, Disk('/d/a.json', '{\n  "a": 1\n}'));
    final controller = editorController(tester);

    await pressCmd(tester, LogicalKeyboardKey.keyA);
    expect(controller.selectedText, '{\n  "a": 1\n}');

    controller.selection = const CodeLineSelection.collapsed(
      index: 0,
      offset: 0,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(controller.selection.extentIndex, 1);
    expect(controller.selection.extentOffset, 1);
  }, variant: macOS);

  testWidgets('edit, save and reopen gives the edited content', (tester) async {
    final disk = Disk('/d/a.json', '{"a": 1}');
    await openApp(tester, disk);
    final controller = editorController(tester);
    controller.selection = const CodeLineSelection.collapsed(
      index: 0,
      offset: 7,
    );
    await tester.pump();
    await typeText(tester, '23');

    await pressCmd(tester, LogicalKeyboardKey.keyS);

    expect(disk.files['/d/a.json'], '{\n  "a": 123\n}\n');
    await tester.tap(find.byTooltip('Open'));
    await tester.pumpAndSettle();
    expect(editorShowing('{\n  "a": 123\n}\n'), findsOneWidget);
  }, variant: macOS);

  testWidgets('invalid text is not written and the error shows where', (
    tester,
  ) async {
    final disk = Disk('/d/a.json', '{"a": 1}');
    await openApp(tester, disk);
    final controller = editorController(tester);
    controller.selection = const CodeLineSelection.collapsed(
      index: 0,
      offset: 7,
    );
    await tester.pump();
    await typeText(tester, ',');

    await pressCmd(tester, LogicalKeyboardKey.keyS);

    expect(disk.files['/d/a.json'], '{"a": 1}', reason: 'file untouched');
    expect(find.textContaining("Can't save a.json"), findsOneWidget);
    expect(find.textContaining('Line 1, column 9'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(controller.text, '{"a": 1,}', reason: 'the edit is kept');
  }, variant: macOS);
}
