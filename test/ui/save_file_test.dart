import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/document/json_document.dart';
import 'package:json_better_editor/l10n/app_localizations.dart';
import 'package:json_better_editor/ui/file_access.dart';
import 'package:json_better_editor/ui/main_window.dart';

const windowChannel = MethodChannel('json_better_editor/window');

/// In-memory stand-in for the disk and the save panel.
class FakeDisk {
  final files = <String, String>{};
  String? nextSavePath;
  final askedNames = <String>[];
  Object? writeError;

  Future<PickedFile?> Function() opener(String path) =>
      () async => PickedFile(path: path, text: files[path]!);

  Future<String?> chooseSavePath(String suggestedName) async {
    askedNames.add(suggestedName);
    return nextSavePath;
  }

  Future<void> write(String path, String text) async {
    if (writeError != null) throw writeError!;
    files[path] = text;
  }
}

Future<void> pumpApp(WidgetTester tester, FakeDisk disk, String openPath) =>
    tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainWindow(
          pickJsonFile: disk.opener(openPath),
          chooseSavePath: disk.chooseSavePath,
          writeTextFile: disk.write,
        ),
      ),
    );

Future<void> open(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Open'));
  await tester.pumpAndSettle();
}

Future<void> pressSave(WidgetTester tester, {bool shift = false}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
  await tester.pumpAndSettle();
}

String modelText(String text) =>
    (parse(text) as ParseSuccess).document.toText();

void main() {
  final titles = <String>[];

  setUp(() {
    titles.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowChannel, (call) async {
          if (call.method == 'setTitle') titles.add(call.arguments as String);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowChannel, null);
  });

  testWidgets(
    'Cmd+S saves pretty-printed JSON that re-opens to the same model',
    (tester) async {
      const original = '{"b":[1,2],"a":{"x":1e5}}';
      final disk = FakeDisk()..files['/d/data.json'] = original;
      await pumpApp(tester, disk, '/d/data.json');
      await open(tester);

      await pressSave(tester);

      final saved = disk.files['/d/data.json']!;
      expect(
        saved,
        '{\n  "b": [\n    1,\n    2\n  ],\n  "a": {\n    "x": 1e5\n  }\n}',
      );
      expect(modelText(saved), modelText(original));
      expect(disk.askedNames, isEmpty, reason: 'Save must not ask for a path');
      expect(find.text(saved), findsOneWidget, reason: 'view shows saved text');
    },
  );

  testWidgets(
    'Cmd+Shift+S asks for a .json path and makes it the current file',
    (tester) async {
      final disk = FakeDisk()
        ..files['/d/a.json'] = '[1]'
        ..nextSavePath = '/d/copy.json';
      await pumpApp(tester, disk, '/d/a.json');
      await open(tester);

      await pressSave(tester, shift: true);

      expect(disk.askedNames, ['a.json']);
      expect(disk.files['/d/copy.json'], '[\n  1\n]');
      expect(disk.files['/d/a.json'], '[1]', reason: 'original untouched');
      expect(titles.last, 'copy.json');

      await pressSave(tester);
      expect(disk.askedNames, ['a.json'], reason: 'Save goes to copy.json now');
      expect(disk.files['/d/copy.json'], '[\n  1\n]');
    },
  );

  testWidgets('cancelling Save As writes nothing', (tester) async {
    final disk = FakeDisk()..files['/d/a.json'] = '[1]';
    await pumpApp(tester, disk, '/d/a.json');
    await open(tester);

    await pressSave(tester, shift: true);

    expect(disk.files.keys, ['/d/a.json']);
    expect(titles.last, 'a.json');
  });

  testWidgets('a write error shows a dialog and keeps the document open', (
    tester,
  ) async {
    final disk = FakeDisk()..files['/d/a.json'] = '[1]';
    await pumpApp(tester, disk, '/d/a.json');
    await open(tester);
    disk.writeError = const FileAccessException(
      '/d/a.json',
      'Operation not permitted',
    );

    await pressSave(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining("Can't save a.json"), findsOneWidget);
    expect(find.textContaining('Operation not permitted'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('[1]'), findsOneWidget);
  });

  testWidgets('saving with no document open does nothing', (tester) async {
    final disk = FakeDisk()..nextSavePath = '/d/x.json';
    await pumpApp(tester, disk, '/d/none.json');

    await pressSave(tester);
    await pressSave(tester, shift: true);

    expect(disk.files, isEmpty);
    expect(disk.askedNames, isEmpty);
  });

  testWidgets('a Save As write error keeps the old current file', (
    tester,
  ) async {
    final disk = FakeDisk()
      ..files['/d/a.json'] = '[1]'
      ..nextSavePath = '/locked/b.json';
    await pumpApp(tester, disk, '/d/a.json');
    await open(tester);
    disk.writeError = const FileAccessException('/locked/b.json', 'denied');

    await pressSave(tester, shift: true);
    expect(find.textContaining("Can't save b.json"), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    disk.writeError = null;
    await pressSave(tester);
    expect(disk.files['/d/a.json'], '[\n  1\n]', reason: 'still a.json');
    expect(titles.last, 'a.json');
  });

  testWidgets('Cmd+S works while the text view has focus', (tester) async {
    final disk = FakeDisk()..files['/d/a.json'] = '[1]';
    await pumpApp(tester, disk, '/d/a.json');
    await open(tester);

    await tester.tap(find.text('[1]'));
    await tester.pumpAndSettle();
    await pressSave(tester);

    expect(disk.files['/d/a.json'], '[\n  1\n]');
  });
}
