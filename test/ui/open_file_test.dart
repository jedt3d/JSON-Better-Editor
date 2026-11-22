import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/l10n/app_localizations.dart';
import 'package:json_better_editor/ui/file_access.dart';
import 'package:json_better_editor/ui/main_window.dart';

const windowChannel = MethodChannel('json_better_editor/window');

Widget appWith(PickJsonFile pick) => MaterialApp(
  localizationsDelegates: appLocalizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: MainWindow(pickJsonFile: pick),
);

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

  testWidgets('opening a valid file shows its text and sets the title', (
    tester,
  ) async {
    const text = '{\n  "name": "Ada"\n}';
    await tester.pumpWidget(
      appWith(
        () async => const PickedFile(path: '/tmp/people.json', text: text),
      ),
    );

    await tester.tap(find.byTooltip('Open'));
    await tester.pumpAndSettle();

    expect(find.text(text), findsOneWidget);
    expect(find.text('Open a JSON file'), findsNothing);
    expect(titles.last, 'people.json');
  });

  testWidgets('opening invalid JSON shows the error and keeps the old state', (
    tester,
  ) async {
    var next = const PickedFile(path: '/tmp/good.json', text: '[1]');
    await tester.pumpWidget(appWith(() async => next));
    await tester.tap(find.byTooltip('Open'));
    await tester.pumpAndSettle();

    next = const PickedFile(path: '/tmp/bad.json', text: '{\n  "a": 1,\n}');
    await tester.tap(find.byTooltip('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('bad.json'), findsOneWidget);
    expect(find.textContaining('Line 3, column 1'), findsOneWidget);
    expect(find.textContaining('Trailing comma'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('[1]'), findsOneWidget);
    expect(titles.last, 'good.json');
  });

  testWidgets('cancelling the picker changes nothing', (tester) async {
    await tester.pumpWidget(appWith(() async => null));

    await tester.tap(find.byTooltip('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Open a JSON file'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('a file that cannot be read shows an error dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      appWith(
        () async => throw const FileAccessException('/tmp/x.json', 'denied'),
      ),
    );

    await tester.tap(find.byTooltip('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('denied'), findsOneWidget);
  });

  testWidgets('New clears the document back to the empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      appWith(() async => const PickedFile(path: '/tmp/a.json', text: '{}')),
    );
    await tester.tap(find.byTooltip('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('New'));
    await tester.pumpAndSettle();

    expect(find.text('Open a JSON file'), findsOneWidget);
    expect(titles.last, 'JSON Better Editor');
  });

  testWidgets('a file that is not UTF-8 text shows an error dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      appWith(() async => throw const FileAccessException('/tmp/b.json')),
    );

    await tester.tap(find.byTooltip('Open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('not UTF-8'), findsOneWidget);
  });

  testWidgets('Open is ignored while a previous Open is still running', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      appWith(() async {
        calls++;
        await Future<void>.delayed(const Duration(seconds: 1));
        return null;
      }),
    );

    await tester.tap(find.byTooltip('Open'));
    await tester.tap(find.byTooltip('Open'));
    await tester.pump(const Duration(seconds: 2));

    expect(calls, 1);
  });
}
