import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../document/json_document.dart';
import '../l10n/app_localizations.dart';

/// Shows the error list above [anchor] (the Status Bar's JSON status item),
/// like an IDE's list after a failed compile (#101, decision #88). Resolves
/// to the error the user chose (double-click, or Return on the selected
/// row), or null when closed with Esc or a click outside.
Future<JsonParseError?> showErrorPopover(
  BuildContext anchor,
  List<JsonParseError> errors,
) {
  final box = anchor.findRenderObject()! as RenderBox;
  final rect = box.localToGlobal(Offset.zero) & box.size;
  return Navigator.of(anchor).push(_ErrorPopoverRoute(rect, errors));
}

class _ErrorPopoverRoute extends PopupRoute<JsonParseError> {
  _ErrorPopoverRoute(this.anchor, this.errors);

  final Rect anchor;
  final List<JsonParseError> errors;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true; // A click outside closes it.

  @override
  String? get barrierLabel => 'Close';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 100);

  @override
  Widget buildPage(context, animation, secondaryAnimation) {
    final screen = MediaQuery.sizeOf(context);
    // Proportional to the window, never fixed pixels (decision #48).
    final width = (screen.width * 0.6).clamp(0.0, screen.width - 16);
    final height = screen.height * 0.35;
    const arrow = 8.0;
    final left = (anchor.center.dx - width / 2).clamp(
      8.0,
      screen.width - width - 8,
    );
    return Stack(
      children: [
        Positioned(
          left: left,
          bottom: screen.height - anchor.top + 2,
          width: width,
          child: FadeTransition(
            opacity: animation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: height),
                  child: _ErrorTable(errors: errors),
                ),
                // The arrow points at the status item.
                Align(
                  alignment: Alignment(
                    ((anchor.center.dx - left) / width) * 2 - 1,
                    0,
                  ),
                  child: CustomPaint(
                    size: const Size(arrow * 2, arrow),
                    painter: _ArrowPainter(
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorTable extends StatefulWidget {
  const _ErrorTable({required this.errors});

  final List<JsonParseError> errors;

  @override
  State<_ErrorTable> createState() => _ErrorTableState();
}

class _ErrorTableState extends State<_ErrorTable> {
  int _selected = 0;

  void _choose(int i) => Navigator.of(context).pop(widget.errors[i]);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final style = theme.textTheme.bodySmall;
    Widget cells(String location, String message, {TextStyle? textStyle}) =>
        Row(
          children: [
            Expanded(flex: 1, child: Text(location, style: textStyle)),
            Expanded(flex: 3, child: Text(message, style: textStyle)),
          ],
        );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () =>
            _choose(_selected),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => setState(
          () => _selected = (_selected + 1).clamp(0, widget.errors.length - 1),
        ),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => setState(
          () => _selected = (_selected - 1).clamp(0, widget.errors.length - 1),
        ),
      },
      child: Focus(
        autofocus: true,
        child: Material(
          key: const Key('errorPopover'),
          color: colors.surfaceContainerHighest,
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                child: cells(
                  l10n.errorsLocation,
                  l10n.errorsMessage,
                  textStyle: style?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.errors.length,
                  itemBuilder: (context, i) {
                    final e = widget.errors[i];
                    return GestureDetector(
                      key: Key('errorRow$i'),
                      onTap: () => setState(() => _selected = i),
                      onDoubleTap: () => _choose(i),
                      child: Container(
                        color: i == _selected ? colors.primaryContainer : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: cells(
                          l10n.errorsAt(e.line, e.column),
                          e.message,
                          textStyle: style,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color;
}
