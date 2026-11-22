import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';

/// re_editor picks its shortcut set (Cmd or Ctrl) from the platform the
/// first time it is used, so editor tests run as macOS, the app's platform.
final macOS = TargetPlatformVariant.only(TargetPlatform.macOS);

/// The Text pane editor, whose text is not a plain Text widget.
final Finder textEditor = find.byType(CodeEditor);

/// The Text pane editor while it holds exactly [text].
Finder editorShowing(String text) => find.byWidgetPredicate(
  (w) => w is CodeEditor && w.controller?.text == text,
  description: 'Text pane showing ${text.length} characters',
);

/// The Text pane's controller.
CodeLineEditingController editorController(WidgetTester tester) =>
    tester.widget<CodeEditor>(textEditor).controller!;

/// Types [text] (no line breaks) at the caret, the way the macOS text input
/// does: re_editor uses the delta model, which flutter_test has no helper
/// for. Sent as one insertion, because re_editor does not echo its editing
/// state back after each change; set the selection before each call.
Future<void> typeText(WidgetTester tester, String text) async {
  final input = tester.testTextInput;
  final clientId =
      input.log.lastWhere((c) => c.method == 'TextInput.setClient').arguments[0]
          as int;
  final state = input.editingState!;
  final base = state['selectionBase'] as int;
  final extent = state['selectionExtent'] as int;
  final from = base < extent ? base : extent;
  final to = base < extent ? extent : base;
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.textInput.name,
    SystemChannels.textInput.codec.encodeMethodCall(
      MethodCall('TextInputClient.updateEditingStateWithDeltas', [
        clientId,
        {
          'deltas': [
            {
              'oldText': state['text'],
              'deltaText': text,
              'deltaStart': from,
              'deltaEnd': to,
              'selectionBase': from + text.length,
              'selectionExtent': from + text.length,
              'selectionAffinity': 'TextAffinity.downstream',
              'selectionIsDirectional': false,
              'composingBase': -1,
              'composingExtent': -1,
            },
          ],
        },
      ]),
    ),
    (_) {},
  );
  await tester.pumpAndSettle();
}

/// Presses [key] with the Command key held, plus Shift when [shift].
Future<void> pressCmd(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
  await tester.pumpAndSettle();
}
