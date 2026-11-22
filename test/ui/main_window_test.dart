import 'package:material_ui/material_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';

const leftGroup = ['New', 'Open', 'Search'];
const rightGroup = [
  'Text only',
  'Node only',
  'Split view',
  'Language',
  'Theme',
  'Settings',
];

double _x(WidgetTester tester, String tooltip) =>
    tester.getCenter(find.byTooltip(tooltip)).dx;

void main() {
  testWidgets('toolbar has every button, left and right groups in order', (
    tester,
  ) async {
    await tester.pumpWidget(const JsonBetterEditorApp());

    final all = [...leftGroup, ...rightGroup];
    for (final tooltip in all) {
      expect(find.byTooltip(tooltip), findsOneWidget, reason: tooltip);
    }
    for (var i = 1; i < all.length; i++) {
      expect(
        _x(tester, all[i - 1]),
        lessThan(_x(tester, all[i])),
        reason: '${all[i - 1]} before ${all[i]}',
      );
    }
    // Groups sit at opposite ends of the window.
    final width = tester.getSize(find.byType(Scaffold)).width;
    expect(_x(tester, 'Search'), lessThan(width / 2));
    expect(_x(tester, 'Text only'), greaterThan(width / 2));
  });

  testWidgets('placeholder buttons show a Coming soon message', (tester) async {
    await tester.pumpWidget(const JsonBetterEditorApp());

    await tester.tap(find.byTooltip('Settings'));
    await tester.pump();

    expect(find.text('Coming soon'), findsOneWidget);
  });

  testWidgets('shows an empty state when no document is loaded', (
    tester,
  ) async {
    await tester.pumpWidget(const JsonBetterEditorApp());

    expect(find.text('Open a JSON file'), findsOneWidget);
  });

  testWidgets('a very narrow window cuts the toolbar off without errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(200, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const JsonBetterEditorApp());

    expect(tester.takeException(), isNull);
  });

  testWidgets('toolbar leaves room for the traffic-light buttons', (
    tester,
  ) async {
    await tester.pumpWidget(const JsonBetterEditorApp());

    expect(tester.getTopLeft(find.byTooltip('New')).dx, greaterThan(84));
  });

  testWidgets('the document title is shown under the toolbar', (tester) async {
    await tester.pumpWidget(const JsonBetterEditorApp());

    final title = find.byKey(const Key('documentTitle'));
    expect(tester.widget<Text>(title).data, 'JSON Better Editor');
    expect(
      tester.getTopLeft(title).dy,
      greaterThan(tester.getBottomLeft(find.byTooltip('Open')).dy),
    );
  });

  group('native-looking macOS toolbar buttons', () {
    ButtonStyle styleOf(WidgetTester tester, String tooltip) => tester
        .widget<IconButton>(
          find.ancestor(
            of: find.byTooltip(tooltip),
            matching: find.byType(IconButton),
          ),
        )
        .style!;

    testWidgets('are borderless with a fill only on hover and press', (
      tester,
    ) async {
      await tester.pumpWidget(const JsonBetterEditorApp());

      final style = styleOf(tester, 'Open');
      Color? fill(Set<WidgetState> states) =>
          style.backgroundColor!.resolve(states);

      expect(style.side?.resolve({}), anyOf(isNull, BorderSide.none));
      expect(fill({})!.a, 0);
      expect(fill({WidgetState.hovered})!.a, greaterThan(0));
      expect(
        fill({WidgetState.pressed})!.a,
        greaterThan(fill({WidgetState.hovered})!.a),
      );
      final shape = style.shape!.resolve({}) as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(6));
    });

    testWidgets('are 28 pt targets centred in the 52 pt title bar', (
      tester,
    ) async {
      await tester.pumpWidget(const JsonBetterEditorApp());

      final button = find.ancestor(
        of: find.byTooltip('Open'),
        matching: find.byType(IconButton),
      );
      expect(tester.getSize(button), const Size(28, 28));
      expect(tester.getCenter(button).dy, 26);
    });
  });

  group('empty toolbar area acts like a title bar', () {
    const channel = MethodChannel('json_better_editor/window');
    final calls = <String>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    Offset emptySpot(WidgetTester tester) {
      final search = tester.getCenter(find.byTooltip('Search'));
      final textOnly = tester.getCenter(find.byTooltip('Text only'));
      return Offset((search.dx + textOnly.dx) / 2, search.dy);
    }

    testWidgets('dragging it moves the window', (tester) async {
      await tester.pumpWidget(const JsonBetterEditorApp());

      await tester.dragFrom(emptySpot(tester), const Offset(40, 20));
      await tester.pumpAndSettle();

      expect(calls, contains('startWindowDrag'));
    });

    testWidgets('double-clicking it acts like the title bar', (tester) async {
      await tester.pumpWidget(const JsonBetterEditorApp());

      await tester.tapAt(emptySpot(tester));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(emptySpot(tester));
      await tester.pumpAndSettle();

      expect(calls, contains('titleBarDoubleClick'));
    });

    testWidgets('pressing a button does not move the window', (tester) async {
      await tester.pumpWidget(const JsonBetterEditorApp());

      await tester.drag(
        find.byTooltip('Settings'),
        const Offset(40, 0),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();

      expect(calls, isNot(contains('startWindowDrag')));
    });
  });
}
