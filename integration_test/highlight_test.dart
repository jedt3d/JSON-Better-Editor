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

/// `--dart-define=HOLD_FOR_SCREENSHOT=true` holds each theme on screen for
/// a few seconds so the real app can be captured in light and dark.
const holdForScreenshot = bool.fromEnvironment('HOLD_FOR_SCREENSHOT');

const valid = '{"name": "Ada"}';

/// Edited into the pane after opening (Open rejects invalid JSON), with an
/// unfinished literal and an unclosed string at the end.
const sample = '''{
  "name": "Ada Lovelace",
  "born": 1815,
  "ratio": -1.5e3,
  "active": true,
  "retired": false,
  "spouse": null,
  "langs": ["en", "fr"],
  "broken": tru,
  "open": "unclosed
}''';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('real app: highlighting in ${mode.name} mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: mode,
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MainWindow(
            pickJsonFile: () async =>
                const PickedFile(path: '/tmp/sample.json', text: valid),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Open'));
      await tester.pumpAndSettle();
      editorController(tester)
        ..text = sample
        // Caret just after `[` on the "langs" line: the pair is boxed (#35).
        ..selection = const CodeLineSelection.collapsed(index: 7, offset: 12);
      // Highlighting runs in an isolate; give it a moment.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(editorShowing(sample), findsOneWidget);
      if (holdForScreenshot) {
        await Future<void>.delayed(const Duration(seconds: 5));
      }
    }, variant: macOS);
  }
}
