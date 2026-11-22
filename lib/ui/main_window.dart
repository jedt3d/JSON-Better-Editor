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
    Widget button(IconData icon, String tooltip) =>
        _ToolbarButton(icon: icon, tooltip: tooltip);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          button(Icons.note_add_outlined, l10n.toolbarNew),
          button(Icons.folder_open_outlined, l10n.toolbarOpen),
          const SizedBox(height: 24, child: VerticalDivider(width: 16)),
          button(Icons.search, l10n.toolbarSearch),
          const Spacer(),
          button(Icons.notes, l10n.toolbarLayoutText),
          button(Icons.account_tree_outlined, l10n.toolbarLayoutNode),
          button(Icons.vertical_split_outlined, l10n.toolbarLayoutSplit),
          button(Icons.translate, l10n.toolbarLanguage),
          button(Icons.contrast, l10n.toolbarTheme),
          button(Icons.settings_outlined, l10n.toolbarSettings),
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
