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

/// `--dart-define=HOLD_FOR_SCREENSHOT=true` holds the folded and unfolded
/// states on screen for a few seconds each.
const holdForScreenshot = bool.fromEnvironment('HOLD_FOR_SCREENSHOT');

const text =
    '{\n'
    '  "person": {\n'
    '    "name": "Ada",\n'
    '    "langs": [\n'
    '      "en",\n'
    '      "fr"\n'
    '    ]\n'
    '  },\n'
    '  "active": true\n'
    '}';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real app: fold markers fold and unfold a block', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainWindow(
          pickJsonFile: () async =>
              const PickedFile(path: '/tmp/fold.json', text: text),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Open'));
    await tester.pumpAndSettle();
    final indicator = find.byType(DefaultCodeChunkIndicator);
    CodeChunkController chunks() =>
        tester.widget<DefaultCodeChunkIndicator>(indicator).controller;
    for (var i = 0; i < 50 && chunks().value.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (holdForScreenshot)
      await Future<void>.delayed(const Duration(seconds: 4));

    chunks().collapse(1);
    await tester.pumpAndSettle();
    final controller = editorController(tester);
    expect(controller.codeLines.length, 4);
    expect(controller.text, text);
    if (holdForScreenshot)
      await Future<void>.delayed(const Duration(seconds: 4));
  }, variant: macOS);
}
