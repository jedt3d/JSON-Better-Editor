import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/app/theme.dart';
import 'package:json_better_editor/l10n/app_localizations.dart';
import 'package:json_better_editor/ui/file_access.dart';
import 'package:json_better_editor/ui/main_window.dart';
import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

import '../test/ui/editor_support.dart';

/// `--dart-define=HOLD_FOR_SCREENSHOT=true` keeps the window up for a few
/// seconds at the end, so a screenshot of the real app can be taken.
const holdForScreenshot = bool.fromEnvironment('HOLD_FOR_SCREENSHOT');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real app: edit a file in the Text pane and save it to disk', (
    tester,
  ) async {
    final dir = await Directory.systemTemp.createTemp('jbe');
    final file = File('${dir.path}/sample.json')
      ..writeAsStringSync('{"name": "Ada", "langs": ["en", "th"]}');
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        darkTheme: darkTheme,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainWindow(
          pickJsonFile: () async =>
              PickedFile(path: file.path, text: file.readAsStringSync()),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Open'));
    await tester.pumpAndSettle();
    await tester.tap(textEditor);
    await tester.pumpAndSettle();

    // The live binding has no fake text input, so edit through the
    // editor's controller (typing itself is covered by test/ui).
    editorController(tester)
      ..selection = const CodeLineSelection.collapsed(index: 0, offset: 13)
      ..replaceSelection(' Lovelace');
    await tester.pumpAndSettle();
    await pressCmd(tester, LogicalKeyboardKey.keyS);
    // The write is real disk I/O; give it time to land.
    for (
      var i = 0;
      i < 30 && !file.readAsStringSync().contains('Lovelace');
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(
      file.readAsStringSync(),
      '{\n  "name": "Ada Lovelace",\n  "langs": [\n    "en",\n    "th"\n  ]\n}\n',
    );
    if (holdForScreenshot) {
      await Future<void>.delayed(const Duration(seconds: 6));
    }
    dir.deleteSync(recursive: true);
  }, variant: macOS);
}
