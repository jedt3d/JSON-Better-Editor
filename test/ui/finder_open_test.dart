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

/// Finder "Open With" (#32): AppDelegate.swift sends `openPath`, and a file
/// that launched the app waits for `takePendingOpenPaths`.
void main() {
  late List<String> pending;
  final files = {'/d/a.json': '[1]', '/d/b.json': '{"b": 2}'};

  setUp(() {
    pending = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowChannel, (call) async {
          if (call.method == 'takePendingOpenPaths') return pending;
          return null;
        });
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainWindow(
          readJsonFile: (path) async =>
              PickedFile(path: path, text: files[path]!),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> finderOpens(WidgetTester tester, String path) async {
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      windowChannel.name,
      windowChannel.codec.encodeMethodCall(MethodCall('openPath', path)),
      (_) {},
    );
    await tester.pumpAndSettle();
  }

  String documentTitle(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('documentTitle'))).data!;

  testWidgets('a file that launched the app is opened', (tester) async {
    pending = ['/d/a.json'];
    await pumpApp(tester);
    expect(documentTitle(tester), 'a.json');
    expect(editorShowing('[1]'), findsOneWidget);
  }, variant: macOS);

  testWidgets('a running window replaces its document', (tester) async {
    await pumpApp(tester);
    await finderOpens(tester, '/d/a.json');
    await finderOpens(tester, '/d/b.json');
    expect(documentTitle(tester), 'b.json');
    expect(editorShowing('{"b": 2}'), findsOneWidget);
  }, variant: macOS);

  testWidgets('with unsaved changes it asks first; Cancel keeps the edits', (
    tester,
  ) async {
    await pumpApp(tester);
    await finderOpens(tester, '/d/a.json');
    await tester.tap(textEditor);
    await tester.pumpAndSettle();
    editorController(tester).selection = const CodeLineSelection.collapsed(
      index: 0,
      offset: 2,
    );
    await tester.pump();
    await typeText(tester, ', 2');

    await finderOpens(tester, '/d/b.json');
    expect(
      find.text('Do you want to save the changes made to “a.json”?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(documentTitle(tester), 'a.json — Edited');

    await finderOpens(tester, '/d/b.json');
    await tester.tap(find.text("Don't Save"));
    await tester.pumpAndSettle();
    expect(documentTitle(tester), 'b.json');
  }, variant: macOS);
}
