// ─────────────────────────────────────────────────────────────────────────────
// ScreenHeader – thin compatibility wrapper around GlobalAppHeader.
//
// All existing screens calling  ScreenHeader(title: '...')  continue to work
// without any changes. The visual output now uses the premium GlobalAppHeader.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'global_app_header.dart';

class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool? showIcons;
  final bool? showBackButton;

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
      // Page screens are already inside a SafeArea-padded ListView so no
      // extra top inset is needed here.
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
    );
  }
}
