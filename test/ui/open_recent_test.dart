import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/l10n/app_localizations.dart';
import 'package:json_better_editor/ui/file_access.dart';
import 'package:json_better_editor/ui/main_window.dart';
import 'package:material_ui/material_ui.dart';

import 'editor_support.dart';

const windowChannel = MethodChannel('json_better_editor/window');

/// File › Open Recent (#92) against a fake native side.
void main() {
  late List<String> stored;
  late Set<String> missing;
  late List<String> remembered;

  setUp(() {
    stored = ['/d/old.json'];
    missing = {};
    remembered = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowChannel, (call) async {
          switch (call.method) {
            case 'loadRecentFiles':
              return stored;
            case 'saveRecentFiles':
              stored = List<String>.from(call.arguments as List);
            case 'rememberRecent':
              remembered.add(call.arguments as String);
            case 'accessRecent':
              final path = call.arguments as String;
              return missing.contains(path) ? null : path;
          }
          return null;
        });
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainWindow(
          pickJsonFile: () async =>
              const PickedFile(path: '/d/new.json', text: '[1]'),
          readJsonFile: (path) async => PickedFile(path: path, text: '[2]'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> native(WidgetTester tester, String method, String arg) async {
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      windowChannel.name,
      windowChannel.codec.encodeMethodCall(MethodCall(method, arg)),
      (_) {},
    );
    await tester.pumpAndSettle();
  }

  String documentTitle(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('documentTitle'))).data!;

  testWidgets('opening a file adds it first and asks for a bookmark', (
    tester,
  ) async {
    await pumpApp(tester);
    await pressCmd(tester, LogicalKeyboardKey.keyO);
    expect(stored, ['/d/new.json', '/d/old.json']);
    expect(remembered, ['/d/new.json']);
  }, variant: macOS);

  testWidgets('choosing an entry opens it (list kept between launches)', (
    tester,
  ) async {
    await pumpApp(tester);
    await native(tester, 'openRecent', '/d/old.json');
    expect(documentTitle(tester), 'old.json');
    expect(stored.first, '/d/old.json');
  }, variant: macOS);

  testWidgets('a missing file shows an error and leaves the list', (
    tester,
  ) async {
    missing.add('/d/old.json');
    await pumpApp(tester);
    await native(tester, 'openRecent', '/d/old.json');
    expect(find.text("Can't open old.json"), findsOneWidget);
    expect(stored, isEmpty);
  }, variant: macOS);

  testWidgets('Clear Menu empties the list', (tester) async {
    await pumpApp(tester);
    await native(tester, 'menu', 'clearRecent');
    expect(stored, isEmpty);
  }, variant: macOS);
}
