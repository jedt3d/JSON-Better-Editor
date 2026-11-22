import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/l10n/app_localizations.dart';
import 'package:json_better_editor/ui/file_access.dart';
import 'package:json_better_editor/ui/main_window.dart';
import 'package:material_ui/material_ui.dart';

import 'editor_support.dart';

const windowChannel = MethodChannel('json_better_editor/window');

/// The File menu lives in AppDelegate.swift; each item sends
/// `menu(<item>)` on the window channel. Close is AppKit's performClose:,
/// which sends `confirmClose` (covered in unsaved_changes_test.dart).
void main() {
  late List<String> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowChannel, (_) async => null);
  });

  Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MainWindow(
        pickJsonFile: () async {
          calls.add('open');
          return const PickedFile(path: '/d/a.json', text: '[1]');
        },
        chooseSavePath: (_) async {
          calls.add('panel');
          return null;
        },
        writeTextFile: (path, _) async => calls.add('write $path'),
      ),
    ),
  );

  Future<void> menu(WidgetTester tester, String item) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      windowChannel.name,
      windowChannel.codec.encodeMethodCall(MethodCall('menu', item)),
      (_) {},
    );
    await tester.pumpAndSettle();
  }

  String documentTitle(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('documentTitle'))).data!;

  testWidgets('File › New makes an Untitled document', (tester) async {
    await pumpApp(tester);
    await menu(tester, 'new');
    expect(documentTitle(tester), 'Untitled');
  }, variant: macOS);

  testWidgets('File › Open… shows the open panel and opens the file', (
    tester,
  ) async {
    await pumpApp(tester);
    await menu(tester, 'open');
    expect(calls, ['open']);
    expect(documentTitle(tester), 'a.json');
  }, variant: macOS);

  testWidgets('File › Save writes the current file', (tester) async {
    await pumpApp(tester);
    await menu(tester, 'open');
    await menu(tester, 'save');
    expect(calls, ['open', 'write /d/a.json']);
  }, variant: macOS);

  testWidgets('File › Save As… shows the save panel', (tester) async {
    await pumpApp(tester);
    await menu(tester, 'open');
    await menu(tester, 'saveAs');
    expect(calls, ['open', 'panel']);
  }, variant: macOS);

  testWidgets('closing the window clears the document for the next show', (
    tester,
  ) async {
    await pumpApp(tester);
    await menu(tester, 'open');
    expect(documentTitle(tester), 'a.json');
    await menu(tester, 'closeDocument');
    expect(documentTitle(tester), 'JSON Better Editor');
    expect(find.text('Open a JSON file'), findsOneWidget);
  }, variant: macOS);
}
