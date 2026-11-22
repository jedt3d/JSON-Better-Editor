import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/document/line_endings.dart';
import 'package:json_better_editor/l10n/app_localizations.dart';
import 'package:json_better_editor/ui/file_access.dart';
import 'package:json_better_editor/ui/main_window.dart';
import 'package:material_ui/material_ui.dart';

import 'editor_support.dart';

const windowChannel = MethodChannel('json_better_editor/window');

/// The LF / CRLF pill in the Status Bar (#104).
void main() {
  late Map<String, String> files;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowChannel, (_) async => null);
  });

  Future<void> open(WidgetTester tester, String source) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    files = {'/d/a.json': source};
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainWindow(
          pickJsonFile: () async =>
              PickedFile(path: '/d/a.json', text: files['/d/a.json']!),
          writeTextFile: (path, text) async => files[path] = text,
          fileModifiedTime: (_) async => null,
        ),
      ),
    );
    await pressCmd(tester, LogicalKeyboardKey.keyO);
  }

  Finder pill() => find.byKey(const Key('lineEndingPill'));

  String pillText(WidgetTester tester) => tester
      .widget<Text>(find.descendant(of: pill(), matching: find.byType(Text)))
      .data!;

  String title(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('documentTitle'))).data!;

  Future<void> choose(WidgetTester tester, String item) async {
    await tester.tap(pill());
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(CheckedPopupMenuItem<LineEnding>, item),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the ending found on Open, and LF for a new document', (
    tester,
  ) async {
    await open(tester, '{\r\n"a": 1\r\n}\r\n');
    expect(pillText(tester), 'CRLF');
    await pressCmd(tester, LogicalKeyboardKey.keyN);
    await tester.pumpAndSettle();
    expect(pillText(tester), 'LF');
  }, variant: macOS);

  testWidgets('changing it marks the document edited; Save writes it', (
    tester,
  ) async {
    await open(tester, '{\r\n"a": 1\r\n}\r\n');
    expect(title(tester), 'a.json');

    await choose(tester, 'CRLF (Windows)');
    expect(title(tester), 'a.json', reason: 'same ending: no change');

    await choose(tester, 'LF (macOS, Linux)');
    expect(pillText(tester), 'LF');
    expect(title(tester), contains('Edited'));

    await choose(tester, 'CRLF (Windows)');
    expect(title(tester), 'a.json', reason: 'back to the saved ending');

    await choose(tester, 'LF (macOS, Linux)');
    await pressCmd(tester, LogicalKeyboardKey.keyS);
    await tester.pumpAndSettle();
    expect(files['/d/a.json'], '{\n  "a": 1\n}\n');
    expect(title(tester), 'a.json', reason: 'saved');
    expect(pillText(tester), 'LF');
  }, variant: macOS);
}
