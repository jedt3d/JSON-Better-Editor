import 'package:flutter/material.dart';
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

  testWidgets('toolbar fits at the minimum window size (640x400)',
      (tester) async {
    tester.view.physicalSize = const Size(640, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const JsonBetterEditorApp());

    expect(tester.takeException(), isNull);
  });
}
