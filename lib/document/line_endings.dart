/// The line ending a file uses, kept on Save (#95). Editing always uses LF.
enum LineEnding {
  lf('\n'),
  crlf('\r\n'),
  cr('\r');

  const LineEnding(this.text);

  final String text;

  /// New documents and files with no line break: the OS default (LF on
  /// macOS and Linux, CRLF on Windows).
  static const osDefault = lf;

  /// The most common line ending in [text]; [osDefault] when it has none.
  /// On a tie, CRLF wins over LF, and LF over CR.
  static LineEnding detect(String text) {
    var crlf = 0, lf = 0, cr = 0;
    for (var i = 0; i < text.length; i++) {
      final c = text.codeUnitAt(i);
      if (c == 0x0D) {
        if (i + 1 < text.length && text.codeUnitAt(i + 1) == 0x0A) {
          crlf++;
          i++;
        } else {
          cr++;
        }
      } else if (c == 0x0A) {
        lf++;
      }
    }
    if (crlf + lf + cr == 0) return osDefault;
    if (crlf >= lf && crlf >= cr) return LineEnding.crlf;
    return lf >= cr ? LineEnding.lf : LineEnding.cr;
  }

  /// [text] with every line ending turned into LF, for editing.
  static String toLf(String text) =>
      text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  /// LF-only [text] written with this line ending.
  String apply(String text) =>
      this == lf ? text : text.replaceAll('\n', this.text);
}
