import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Main window: toolbar on top, content area below.
class MainWindow extends StatelessWidget {
  const MainWindow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Column(
        children: [
          const _Toolbar(),
          const Divider(height: 1),
          Expanded(child: Center(child: Text(l10n.emptyState))),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _ToolbarButton(
            icon: Icons.note_add_outlined,
            tooltip: l10n.toolbarNew,
          ),
          _ToolbarButton(
            icon: Icons.folder_open_outlined,
            tooltip: l10n.toolbarOpen,
          ),
          const SizedBox(height: 24, child: VerticalDivider(width: 16)),
          _ToolbarButton(icon: Icons.search, tooltip: l10n.toolbarSearch),
          const Spacer(),
          _ToolbarButton(icon: Icons.notes, tooltip: l10n.toolbarLayoutText),
          _ToolbarButton(
            icon: Icons.account_tree_outlined,
            tooltip: l10n.toolbarLayoutNode,
          ),
          _ToolbarButton(
            icon: Icons.vertical_split_outlined,
            tooltip: l10n.toolbarLayoutSplit,
          ),
          _ToolbarButton(icon: Icons.translate, tooltip: l10n.toolbarLanguage),
          _ToolbarButton(icon: Icons.contrast, tooltip: l10n.toolbarTheme),
          _ToolbarButton(
            icon: Icons.settings_outlined,
            tooltip: l10n.toolbarSettings,
          ),
        ],
      ),
    );
  }
}

/// Pill-shaped outlined icon button. Until each feature lands it shows
/// a "Coming soon" message.
class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton.outlined(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: () => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.comingSoon)),
          ),
      ),
    );
  }
}
