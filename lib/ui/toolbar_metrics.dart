/// Size and spacing of the main toolbar for one platform, in logical points
/// (scale-independent, decision #48). Only macOS exists now; Windows and
/// Linux get their own values later (decision #50).
class ToolbarMetrics {
  const ToolbarMetrics({
    required this.height,
    required this.leadingInset,
    required this.trailingInset,
    required this.buttonSize,
    required this.iconSize,
    required this.gap,
    required this.cornerRadius,
  });

  /// macOS unified title bar with toolbar, like Xcode, Finder and Safari.
  /// The traffic lights end 80 pt from the left edge.
  static const macOS = ToolbarMetrics(
    height: 52,
    leadingInset: 88,
    trailingInset: 12,
    buttonSize: 28,
    iconSize: 17,
    gap: 8,
    cornerRadius: 6,
  );

  final double height;
  final double leadingInset;
  final double trailingInset;
  final double buttonSize;
  final double iconSize;
  final double gap;
  final double cornerRadius;

  /// Width [buttons] buttons and one group divider need; narrower windows
  /// cut the toolbar off.
  double naturalWidth(int buttons) =>
      leadingInset + buttons * (buttonSize + gap) + gap * 2 + trailingInset;
}
