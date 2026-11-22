// Performance check for #44 (decision #59). Not part of the app: build it
// with scripts/perf.sh, which runs it as a profile build for several file
// sizes and prints one PERF line per measurement.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/document/bracket_match.dart';
import 'package:json_better_editor/document/json_search.dart';
import 'package:json_better_editor/ui/key_autocomplete.dart';
import 'package:json_better_editor/ui/line_list.dart';
import 'package:material_ui/material_ui.dart';
import 'package:re_editor/re_editor.dart';

/// Pretty-printed JSON of about [bytes] bytes: an array of records with
/// nested objects, arrays and every value type.
String generate(int bytes) {
  final items = <Object?>[];
  var size = 0;
  for (var i = 0; size < bytes; i++) {
    final item = {
      'id': i,
      'name': 'Customer number $i',
      'email': 'customer$i@example.com',
      'active': i.isEven,
      'balance': i * 13.37,
      'tags': ['alpha', 'beta', if (i % 3 == 0) 'gamma'],
      'address': {'street': '$i Main Street', 'city': 'Bangkok', 'zip': null},
    };
    items.add(item);
    size += 330;
  }
  return const JsonEncoder.withIndent('  ').convert(items);
}

void report(String name, Object value) => stdout.writeln('PERF $name=$value');

final frames = <FrameTiming>[];

/// Build+raster time of the frames since the last call, as p50/max in ms.
Future<void> reportFrames(String name) async {
  await Future<void>.delayed(const Duration(milliseconds: 300));
  final total = [
    for (final f in frames)
      (f.buildDuration + f.rasterDuration).inMicroseconds / 1000,
  ]..sort();
  frames.clear();
  if (total.isEmpty) return report('${name}_frames', 0);
  report('${name}_frames', total.length);
  report('${name}_frame_p50_ms', total[total.length ~/ 2].toStringAsFixed(1));
  report('${name}_frame_max_ms', total.last.toStringAsFixed(1));
}

T? findWidget<T extends Widget>() {
  T? found;
  void visit(Element e) {
    if (found != null) return;
    if (e.widget is T) {
      found = e.widget as T;
      return;
    }
    e.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return found;
}

Future<void> nextFrame() async {
  SchedulerBinding.instance.scheduleFrame();
  await SchedulerBinding.instance.endOfFrame;
}

Future<int> timed(Future<void> Function() action) async {
  final sw = Stopwatch()..start();
  await action();
  return sw.elapsedMilliseconds;
}

Future<void> main() async {
  final mb = double.parse(Platform.environment['PERF_MB'] ?? '5');
  final text = generate((mb * 1024 * 1024).round());
  final file = File('${Directory.systemTemp.path}/perf_$mb.json')
    ..writeAsStringSync(text);
  report('file_mb', (file.lengthSync() / 1024 / 1024).toStringAsFixed(2));
  report('lines', '\n'.allMatches(text).length + 1);

  runApp(const JsonBetterEditorApp());
  await nextFrame();
  SchedulerBinding.instance.addTimingsCallback(frames.addAll);

  // Open, as Finder does: read, parse, build the editor, show the text.
  final open = Stopwatch()..start();
  const channel = MethodChannel('json_better_editor/window');
  ServicesBinding.instance.channelBuffers.push(
    channel.name,
    channel.codec.encodeMethodCall(MethodCall('openPath', file.path)),
    (_) {},
  );
  CodeLineEditingController? controller;
  while ((controller = findWidget<CodeEditor>()?.controller) == null) {
    await nextFrame();
  }
  await nextFrame();
  report('open_ms', open.elapsedMilliseconds);
  final c = controller!;
  await reportFrames('open');

  // Save, as Cmd+S does: parse the text, pretty-print, write the file.
  final saved = Completer<void>();
  final save = Stopwatch()..start();
  ServicesBinding.instance.channelBuffers.push(
    channel.name,
    channel.codec.encodeMethodCall(const MethodCall('menu', 'save')),
    (_) => saved.complete(),
  );
  await saved.future;
  report('save_ms', save.elapsedMilliseconds);

  // Fold markers appear when re_editor's isolate has analysed the file.
  final chunks = findWidget<DefaultCodeChunkIndicator>()!.controller;
  final foldWait = Stopwatch()..start();
  while (chunks.value.isEmpty && foldWait.elapsedMilliseconds < 60000) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  report('fold_markers_after_open_ms', foldWait.elapsedMilliseconds);

  final lineCount = c.codeLines.length;

  // One jump from the last line to the first (#67, fork patch 1).
  c.selection = CodeLineSelection.collapsed(index: lineCount - 1, offset: 0);
  c.makeCursorVisible();
  await nextFrame();
  final top = Stopwatch()..start();
  c.selection = const CodeLineSelection.collapsed(index: 0, offset: 0);
  c.makeCursorVisible();
  await nextFrame();
  report('jump_end_to_top_ms', top.elapsedMilliseconds);
  // Typing in the middle and near the end (the edited check compares lines
  // up to the edit).
  for (final (name, line) in [
    ('type_middle', lineCount ~/ 2),
    ('type_end', lineCount - 3),
  ]) {
    c.selection = CodeLineSelection.collapsed(index: line, offset: 0);
    c.makeCursorVisible();
    await nextFrame();
    frames.clear();
    final ms = await timed(() async {
      for (var i = 0; i < 30; i++) {
        c.replaceSelection('x');
        await nextFrame();
      }
    });
    report('${name}_per_key_ms', (ms / 30).toStringAsFixed(1));
    await reportFrames(name);
  }

  // Scrolling: page through the file in 60 jumps.
  frames.clear();
  var slowest = (0, 0);
  final scrollMs = await timed(() async {
    for (var i = 0; i < 60; i++) {
      final one = Stopwatch()..start();
      c.selection = CodeLineSelection.collapsed(
        index: (lineCount - 1) * i ~/ 59,
        offset: 0,
      );
      c.makeCursorVisible();
      await nextFrame();
      if (one.elapsedMilliseconds > slowest.$2) {
        slowest = (i, one.elapsedMilliseconds);
      }
    }
  });
  report('scroll_slowest_jump', '#${slowest.$1} ${slowest.$2} ms');
  report('scroll_per_jump_ms', (scrollMs / 60).toStringAsFixed(1));
  await reportFrames('scroll');

  // Search: a common word and one that is not there.
  final list = lineList(c.codeLines);
  String lineAt(int i) => list[i].text;
  for (final (name, query) in [
    ('search_common', 'city'),
    ('search_none', 'zzzq'),
  ]) {
    final sw = Stopwatch()..start();
    final hits = searchJson([for (final l in list) l.text], query);
    report('${name}_ms', sw.elapsedMilliseconds);
    report('${name}_hits', hits.length);
  }

  // Bracket match from the root `[`: scans the whole file.
  var sw = Stopwatch()..start();
  final pair = matchAt(lineAt, lineCount, (line: 0, column: 1));
  report('bracket_root_ms', sw.elapsedMilliseconds);
  report('bracket_root_found', pair != null);

  // Key suggestions: collect every key (cold, then cached).
  final prompts = JsonKeyPrompts(c);
  final keyLine = CodeLine('    "na');
  for (final name in ['keys_cold', 'keys_warm']) {
    sw = Stopwatch()..start();
    final value = prompts.build(
      WidgetsBinding.instance.rootElement!,
      keyLine,
      CodeLineSelection.collapsed(index: 2, offset: keyLine.text.length),
    );
    report('${name}_ms', sw.elapsedMilliseconds);
    report('${name}_found', value?.prompts.length ?? 0);
  }

  // Folding the root block: the edited check walks all lines once. After
  // the edits above, wait for the analysis to catch up first.
  final wait = Stopwatch()..start();
  var before = chunks.value;
  while (wait.elapsedMilliseconds < 60000) {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (identical(before, chunks.value) && chunks.value.isNotEmpty) break;
    before = chunks.value;
  }
  report('fold_analysis_settled_after_edits_ms', wait.elapsedMilliseconds);
  frames.clear();
  final foldMs = await timed(() async {
    chunks.collapse(0);
    await nextFrame();
  });
  report('fold_root_ms', foldMs);
  await reportFrames('fold');

  file.deleteSync();
  exit(0);
}
