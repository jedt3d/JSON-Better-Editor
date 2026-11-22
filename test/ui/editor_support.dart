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
  // Lay out the edit before time moves on: re_editor places its key
  // suggestions 50 ms after typing, using the laid-out line.
  await tester.pump();
  await tester.pumpAndSettle();
}

/// Types [text] one character at a time, like a person: each character is
/// its own delta, so re_editor's auto-closing and type-over (#91) apply.
/// re_editor only sends its editing state back when it changed the text
/// itself, so the state is tracked here between characters.
Future<void> typeChars(WidgetTester tester, String text) async {
  final input = tester.testTextInput;
  final clientId =
      input.log.lastWhere((c) => c.method == 'TextInput.setClient').arguments[0]
          as int;
  var state = Map<String, dynamic>.of(input.editingState!);
  for (final char in text.split('')) {
    final before = input.editingState;
    final offset = state['selectionExtent'] as int;
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.textInput.name,
      SystemChannels.textInput.codec.encodeMethodCall(
        MethodCall('TextInputClient.updateEditingStateWithDeltas', [
          clientId,
          {
            'deltas': [
              {
                'oldText': state['text'],
                'deltaText': char,
                'deltaStart': offset,
                'deltaEnd': offset,
                'selectionBase': offset + 1,
                'selectionExtent': offset + 1,
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
    await tester.pump();
    final after = input.editingState!;
    if (!identical(after, before)) {
      state = Map<String, dynamic>.of(after); // re_editor sent its own.
    } else {
      final old = state['text'] as String;
      state = {
        ...state,
        'text': old.substring(0, offset) + char + old.substring(offset),
        'selectionBase': offset + 1,
        'selectionExtent': offset + 1,
      };
    }
  }
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
