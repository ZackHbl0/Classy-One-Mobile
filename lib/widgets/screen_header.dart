// ─────────────────────────────────────────────────────────────────────────────
// ScreenHeader – thin compatibility wrapper around GlobalAppHeader.
//
// All existing screens calling  ScreenHeader(title: '...')  continue to work
// without any changes. The visual output now uses the premium GlobalAppHeader.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'global_app_header.dart';

class ScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool? showIcons;
  final bool? showBackButton;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showIcons = true,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlobalAppHeader(
      pageTitle:        title,
      showNotification: showIcons ?? true,
      showProfile:      showIcons ?? true,
      showBackButton:   showBackButton ?? false,
    );
  }
}
