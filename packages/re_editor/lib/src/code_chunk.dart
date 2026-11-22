part of re_editor;

class CodeChunkController extends ValueNotifier<List<CodeChunk>> {

  late final CodeLineEditingController _controller;
  final CodeChunkAnalyzer _analyzer;

  late final _IsolateTasker<_CodeChunkAnalyzePayload, _CodeChunkAnalyzeResult> _tasker;

  late bool _shouldNotUpdateChunks;

  CodeChunkController(CodeLineEditingController controller, this._analyzer) : super(const []) {
    _controller = controller is _CodeLineEditingControllerDelegate ? controller.delegate : controller;
    _controller.addListener(_onCodeChanged);
    _tasker = _IsolateTasker<_CodeChunkAnalyzePayload, _CodeChunkAnalyzeResult>('CodeChunk', _run);
    _shouldNotUpdateChunks = false;
    _runChunkAnalyzeTask();
  }

  void collapse(int index) {
    final CodeChunk? chunk = findByIndex(index);
    if (chunk == null) {
      // Not support to collapse
      return;
    }
    if (!chunk.canCollapse) {
      // Has collapsed or nothing to collapse
      return;
    }
    final List<CodeChunk> codeChunks = List.of(value);
    // Remove sub chunks
    codeChunks.removeWhere((e) => e.index > chunk.index && e.end < chunk.end);
    // Chunks after the collapsed should adjust the offset
    for (int i = 0; i < codeChunks.length; i++) {
      final CodeChunk e = codeChunks[i];
      if (e.index >= index || e.end >= index) {
        codeChunks[i] = CodeChunk(e.index > index ? e.index - chunk.collapseSize : e.index,
          e.end > index ? e.end - chunk.collapseSize : e.end
        );
      }
    }
    value = codeChunks;
    _shouldNotUpdateChunks = true;
    _controller.collapseChunk(chunk.index, chunk.end);
    _shouldNotUpdateChunks = false;
  }

  void expand(int index) {
    final CodeLine codeLine = _controller.codeLines[index];
    if (!codeLine.chunkParent) {
      // Nothing to expand, this should not happen.
      return;
    }
    final List<CodeChunk> codeChunks = List.of(value);
    bool exists = false;
    for (int i = 0; i < codeChunks.length; i++) {
      final CodeChunk e = codeChunks[i];
      if (e.index >= index || e.end >= index) {
        codeChunks[i] = CodeChunk(e.index > index ? e.index + codeLine.chunks.length : e.index,
          e.end > index ? e.end + codeLine.chunks.length : e.end
        );
      }
      if (e.index == index) {
        exists = true;
      }
    }
    // Add self into the chunks if not exists
    if (!exists) {
      codeChunks.add(CodeChunk(index, index + codeLine.chunks.length + 1));
      // sort by index
      codeChunks.sort((a, b) => a.index - b.index);
    }
    value = codeChunks;
    _controller.expandChunk(index);
  }

  void toggle(int index) {
    if (_controller.codeLines[index].chunkParent) {
      expand(index);
    } else {
      collapse(index);
    }
  }

  // JBE: patch 3 — fold or unfold many blocks in one pass (#103). Calling
  // collapse or expand once per block copies every line each time, which is
  // hours for the tens of thousands of blocks in a large file.

  /// Folds the blocks starting at [indexes] (visible line numbers) at once.
  /// A block inside another one in the set is skipped. The caret moves to
  /// the fold line when its line is hidden. One editing step, as [collapse].
  void collapseAll(Iterable<int> indexes) {
    final Set<int> wanted = indexes.toSet();
    final List<CodeChunk> targets = [];
    for (final CodeChunk chunk in value) {
      if (!wanted.contains(chunk.index) || !chunk.canCollapse) {
        continue;
      }
      if (targets.isNotEmpty && chunk.index < targets.last.end - 1) {
        continue; // inside the previous target
      }
      targets.add(chunk);
    }
    if (targets.isEmpty) {
      return;
    }
    final List<CodeLine> lines = [
      for (final CodeLineSegment segment in _controller.codeLines.segments)
        ...segment.codeLines,
    ];
    if (targets.last.end > lines.length) {
      return; // the analysis is behind the text
    }
    // Visible lines before each new index are shifted up by the hidden
    // lines of the targets before them.
    final List<CodeLine> newLines = [];
    int t = 0;
    for (int i = 0; i < lines.length; i++) {
      if (t < targets.length && targets[t].index == i) {
        final CodeChunk chunk = targets[t++];
        newLines
            .add(lines[i].copyWith(chunks: lines.sublist(i + 1, chunk.end)));
        i = chunk.end - 1;
      } else {
        newLines.add(lines[i]);
      }
    }
    // Hidden lines of the first k targets, for shift() in O(log n).
    final List<int> hiddenBefore = [0];
    for (final CodeChunk chunk in targets) {
      hiddenBefore.add(hiddenBefore.last + chunk.collapseSize);
    }
    // Number of targets that start before [position].
    int countBefore(int position) {
      int low = 0;
      int high = targets.length;
      while (low < high) {
        final int mid = (low + high) >> 1;
        if (targets[mid].index < position) {
          low = mid + 1;
        } else {
          high = mid;
        }
      }
      return low;
    }

    int shift(int position) => hiddenBefore[countBefore(position)];
    // The target that hides line [index], if any (targets never overlap).
    CodeChunk? hiding(int index) {
      final int k = countBefore(index);
      if (k == 0) {
        return null;
      }
      final CodeChunk chunk = targets[k - 1];
      return index < chunk.end ? chunk : null;
    }

    final List<CodeChunk> newChunks = [];
    for (final CodeChunk e in value) {
      final CodeChunk? owner = hiding(e.index);
      if (owner != null) {
        continue; // folded away with its block
      }
      newChunks.add(CodeChunk(e.index - shift(e.index), e.end - shift(e.end)));
    }
    CodeLinePosition move(int index, int offset) {
      final CodeChunk? owner = hiding(index);
      if (owner != null) {
        final int line = owner.index - shift(owner.index);
        return CodeLinePosition(
            index: line, offset: lines[owner.index].text.length);
      }
      return CodeLinePosition(index: index - shift(index), offset: offset);
    }

    final CodeLineSelection selection = _controller.selection;
    final CodeLinePosition base =
        move(selection.baseIndex, selection.baseOffset);
    final CodeLinePosition extent =
        move(selection.extentIndex, selection.extentOffset);
    value = newChunks;
    _shouldNotUpdateChunks = true;
    _controller.value = _controller.value.copyWith(
      codeLines: CodeLines.of(newLines),
      selection: selection.copyWith(
        baseIndex: base.index,
        baseOffset: base.offset,
        extentIndex: extent.index,
        extentOffset: extent.offset,
      ),
      composing: TextRange.empty,
    );
    _shouldNotUpdateChunks = false;
  }

  /// Unfolds every folded block, nested ones too, at once. The markers of
  /// blocks inside them come back when the analysis runs again, as with
  /// [expand].
  void expandAll() {
    final List<CodeLine> lines = [
      for (final CodeLineSegment segment in _controller.codeLines.segments)
        ...segment.codeLines,
    ];
    if (!lines.any((e) => e.chunkParent)) {
      return;
    }
    final List<CodeLine> newLines = [];
    final List<int> newIndex = [];
    final List<CodeChunk> opened = [];
    void add(CodeLine line) {
      if (!line.chunkParent) {
        newLines.add(line);
        return;
      }
      final int start = newLines.length;
      newLines.add(line.copyWith(chunks: const []));
      line.chunks.forEach(add);
      opened.add(CodeChunk(start, newLines.length));
    }

    for (final CodeLine line in lines) {
      newIndex.add(newLines.length);
      add(line);
    }
    newIndex.add(newLines.length);
    final List<CodeChunk> newChunks = [
      for (final CodeChunk e in value)
        if (e.index < lines.length && !lines[e.index].chunkParent)
          CodeChunk(newIndex[e.index], newIndex[e.end.clamp(0, lines.length)]),
      ...opened,
    ]..sort((a, b) => a.index - b.index);
    final CodeLineSelection selection = _controller.selection;
    value = newChunks;
    _controller.value = _controller.value.copyWith(
      codeLines: CodeLines.of(newLines),
      selection: selection.copyWith(
        baseIndex: newIndex[selection.baseIndex],
        extentIndex: newIndex[selection.extentIndex],
      ),
    );
  }

  CodeChunk? findByIndex(int index) {
    for (final CodeChunk chunk in value) {
      if (chunk.index == index) {
        return chunk;
      } else if (chunk.index > index) {
        break;
      }
    }
    return null;
  }

  bool canCollapse(int index) {
    return findByIndex(index)?.canCollapse ?? false;
  }

  @override
  void dispose() {
    _controller.removeListener(_onCodeChanged);
    _tasker.close();
    super.dispose();
  }

  void _onCodeChanged() {
    if (_shouldNotUpdateChunks) {
      return;
    }
    if (_controller.codeLines.length < 3 && value.isEmpty) {
      value = [];
      return;
    }
    if (_controller.codeLines.equals(_controller.preValue?.codeLines)) {
      return;
    }
    _runChunkAnalyzeTask();
  }

  void _runChunkAnalyzeTask() {
    final CodeLines codeLines = _controller.codeLines;
    _tasker.run(_CodeChunkAnalyzePayload(_analyzer, codeLines), (result) {
      if (_controller.codeLines.equals(codeLines)) {
        value = result.chunks;
        _expandInvalidCollapsedChunks(result.invalidCollapsedChunkIndexes);
      }
    });
  }

  void _expandInvalidCollapsedChunks(List<int> indexes) {
    // Expand invalid chunks from bottom to top
    for (int i = indexes.length - 1; i >=0; i--) {
      expand(indexes[i]);
    }
  }

  @pragma('vm:entry-point')
  static _CodeChunkAnalyzeResult _run(_CodeChunkAnalyzePayload payload) {
    final List<CodeChunk> chunks = payload.analyzer.run(payload.codeLines);
    final List<int> invalidCollapsedChunkIndexes = [];
    for (int i = 0; i < payload.codeLines.length; i++) {
      if (!payload.codeLines[i].chunkParent) {
        continue;
      }
      final int index = chunks.indexWhere((e) => e.index == i);
      if (index < 0 || chunks[index].canCollapse) {
        invalidCollapsedChunkIndexes.add(i);
      }
    }
    return _CodeChunkAnalyzeResult(chunks, invalidCollapsedChunkIndexes);
  }

}

class CodeChunk {

  final int index;
  final int end;

  const CodeChunk(this.index, this.end);

  bool get canCollapse => collapseSize > 0;

  int get collapseSize => end - index - 1;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CodeChunk
        && other.index == index
        && other.end == end;
  }

  @override
  int get hashCode => Object.hash(index, end);

  @override
  String toString() {
    return '[$index, $end]';
  }

}

abstract class CodeChunkAnalyzer {

  List<CodeChunk> run(CodeLines codeLines);

}

class NonCodeChunkAnalyzer implements CodeChunkAnalyzer {

  const NonCodeChunkAnalyzer();

  @override
  List<CodeChunk> run(CodeLines codeLines) => const [];

}

class DefaultCodeChunkAnalyzer implements CodeChunkAnalyzer {

  static const Map<String, String> _chunkSymbols = {
    '(': ')',
    '[': ']',
    '{': '}'
  };
  static final List<int> _tokens = '"\'()[]{}'.codeUnits;

  const DefaultCodeChunkAnalyzer();

  @override
  List<CodeChunk> run(CodeLines codeLines) {
    final List<CodeChunk> chunks = [];
    final List<CodeChunkSymbol> stack = [];
    final List<CodeChunkSymbol> chunkSymbols = parse(codeLines);
    for (final CodeChunkSymbol symbol in chunkSymbols) {
      if (_chunkSymbols.keys.contains(symbol.value)) {
        stack.add(symbol);
        continue;
      }
      while(stack.isNotEmpty) {
        final CodeChunkSymbol pop = stack.removeLast();
        if (_chunkSymbols[pop.value] == symbol.value) {
          if (symbol.index - pop.index >= 1 && chunks.where((e) => e.index == pop.index).isEmpty) {
            chunks.add(CodeChunk(pop.index, symbol.index));
          }
          break;
        }
      }
    }
    // sort by index
    chunks.sort((a, b) => a.index - b.index);
    return chunks;
  }

  @visibleForTesting
  List<CodeChunkSymbol> parse(CodeLines codeLines) {
    final List<CodeChunkSymbol> symbols = [];
    for (int i = 0; i < codeLines.length; i++) {
      final String text = codeLines[i].text.trim();
      if (text.isEmpty) {
        continue;
      }
      symbols.addAll(_parseLine(text, i));
    }
    return symbols;
  }

  List<CodeChunkSymbol> _parseLine(String text, int index) {
    final List<CodeChunkSymbol> symbols = [];
    const int normal = 0;
    const int inQuote = 1;
    const int inDoubleQuote = 2;
    bool inEscapeQuote = false;
    bool inEscapeDoubleQuote = false;
    int state = normal;
    final List<int> codeUnits = text.codeUnits;
    for (int i = 0; i < codeUnits.length; i++) {
      if (!_tokens.contains(codeUnits[i])) {
        continue;
      }
      final String character = String.fromCharCode(codeUnits[i]);
      if (state == inQuote) {
        if (character == '\'' && !isPreEscapeChar(codeUnits, i)) {
          state = normal;
        }
      } else if (state == inDoubleQuote) {
        if (character == '"' && !isPreEscapeChar(codeUnits, i)) {
          state = normal;
        }
      } else {
        if (character == '\'') {
          if (inEscapeQuote) {
            if (isPreEscapeChar(codeUnits, i)) {
              inEscapeQuote = false;
            } else {
              // Unbalanced escape quotes
              break;
            }
          } else {
            if (isPreEscapeChar(codeUnits, i)) {
              inEscapeQuote = true;
            } else {
              state = inQuote;
            }
          }
        } else if (character == '"') {
          if (inEscapeDoubleQuote) {
            if (isPreEscapeChar(codeUnits, i)) {
              inEscapeDoubleQuote = false;
            } else {
              // Unbalanced escape double quotes
              break;
            }
          } else {
            if (isPreEscapeChar(codeUnits, i)) {
              inEscapeDoubleQuote = true;
            } else {
              state = inDoubleQuote;
            }
          }
        } else {
          if (!inEscapeQuote && !inEscapeDoubleQuote) {
            symbols.add(CodeChunkSymbol(character, index));
          }
        }
      }
    }
    return symbols;
  }

  bool isPreEscapeChar(List<int> codeUnits, int index) {
    return index > 0 && codeUnits[index - 1] == '\\'.codeUnits.first;
  }

}

class CodeChunkSymbol {

  final String value;
  final int index;

  const CodeChunkSymbol(this.value, this.index);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CodeChunkSymbol
        && other.value == value
        && other.index == index;
  }

  @override
  int get hashCode => Object.hash(value, index);

  @override
  String toString() {
    return '$value@$index';
  }

}

class _CodeChunkAnalyzePayload {

  final CodeChunkAnalyzer analyzer;
  final CodeLines codeLines;

  const _CodeChunkAnalyzePayload(this.analyzer, this.codeLines);

}

class _CodeChunkAnalyzeResult {

  final List<CodeChunk> chunks;
  final List<int> invalidCollapsedChunkIndexes;

  const _CodeChunkAnalyzeResult(this.chunks, this.invalidCollapsedChunkIndexes);

}