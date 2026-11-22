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

/// A fake disk whose files have modification times (#88).
class Disk {
  final files = <String, String>{'/d/a.json': '[1]'};
  final modified = <String, DateTime>{'/d/a.json': DateTime(2026, 1, 1)};

  void changeOutside(String text) {
    files['/d/a.json'] = text;
    modified['/d/a.json'] = modified['/d/a.json']!.add(
      const Duration(minutes: 1),
    );
  }

  void delete() {
    files.remove('/d/a.json');
    modified.remove('/d/a.json');
  }
}

void main() {
  late Disk disk;

  setUp(() {
    disk = Disk();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowChannel, (_) async => null);
  });

  Future<CodeLineEditingController> openFile(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainWindow(
          pickJsonFile: () async =>
              PickedFile(path: '/d/a.json', text: disk.files['/d/a.json']!),
          readJsonFile: (path) async =>
              PickedFile(path: path, text: disk.files[path]!),
          writeTextFile: (path, text) async {
            disk.files[path] = text;
            disk.modified[path] = DateTime(2030);
          },
          fileModifiedTime: (path) async => disk.modified[path],
        ),
      ),
    );
    await pressCmd(tester, LogicalKeyboardKey.keyO);
    return editorController(tester);
  }

  /// The app comes back to the front (window gets focus).
  Future<void> refocus(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
  }

  testWidgets('no edits: an outside change asks Reload / Keep Mine', (
    tester,
  ) async {
    final c = await openFile(tester);
    disk.changeOutside('[2]');
    await refocus(tester);
    expect(
      find.text('“a.json” was changed by another program'),
      findsOneWidget,
    );
    expect(
      find.text('Reload it from disk, or keep the version shown here?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Reload'));
    await tester.pumpAndSettle();
    expect(editorController(tester).text, '[2]');
    expect(c.text, '[1]', reason: 'the old controller is replaced');

    await refocus(tester);
    expect(find.byType(AlertDialog), findsNothing, reason: 'asked once');
  }, variant: macOS);

  testWidgets('with unsaved edits the question warns; Keep Mine keeps them', (
    tester,
  ) async {
    final c = await openFile(tester);
    c.text = '[1, 9]';
    await tester.pumpAndSettle();
    disk.changeOutside('[2]');
    await refocus(tester);
    expect(find.textContaining('drops your unsaved changes'), findsOneWidget);
    await tester.tap(find.text('Keep Mine'));
    await tester.pumpAndSettle();
    expect(editorController(tester).text, '[1, 9]');
  }, variant: macOS);

  testWidgets('Save over a changed file asks first; default Cancel', (
    tester,
  ) async {
    final c = await openFile(tester);
    c.text = '[1, 9]';
    await tester.pumpAndSettle();
    disk.changeOutside('[2]');

    await pressCmd(tester, LogicalKeyboardKey.keyS);
    expect(
      find.text('“a.json” changed on disk since you opened it'),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter); // Default: Cancel.
    await tester.pumpAndSettle();
    expect(disk.files['/d/a.json'], '[2]', reason: 'not overwritten');

    await pressCmd(tester, LogicalKeyboardKey.keyS);
    await tester.tap(find.text('Overwrite'));
    await tester.pumpAndSettle();
    expect(disk.files['/d/a.json'], '[\n  1,\n  9\n]\n');
  }, variant: macOS);

  testWidgets('a deleted file is reported once; Save writes it again', (
    tester,
  ) async {
    await openFile(tester);
    disk.delete();
    await refocus(tester);
    expect(find.text('“a.json” was moved or deleted'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await refocus(tester);
    expect(find.byType(AlertDialog), findsNothing);

    await pressCmd(tester, LogicalKeyboardKey.keyS);
    expect(find.byType(AlertDialog), findsNothing);
    expect(disk.files['/d/a.json'], '[\n  1\n]\n');
  }, variant: macOS);
}
