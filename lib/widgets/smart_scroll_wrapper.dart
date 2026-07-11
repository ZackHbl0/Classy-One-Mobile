import 'package:flutter/material.dart';

/// SmartScrollWrapper — global hide-on-scroll-down / show-on-scroll-up layout.
///
/// Wraps any screen body inside a [NestedScrollView] with a floating [SliverAppBar]
/// so the header smoothly hides when the user scrolls down and snaps back on scroll up.
///
/// Usage:
/// ```dart
/// return SmartScrollWrapper(
///   header: GlobalAppHeader(pageTitle: 'Dashboard'),
///   body: YourBodyWidget(),
/// );
/// ```
class SmartScrollWrapper extends StatelessWidget {
  final Widget header;
  final Widget body;

  /// Optional drawer — pass [CustomSidebar()] when the screen should have one.
  final Widget? drawer;

  /// Optional bottom nav bar. Normally not needed for sub-screens; the
  /// [MainScreen] scaffold provides the bottom bar globally.
  final Widget? bottomNavigationBar;

  const SmartScrollWrapper({
    super.key,
    required this.header,
    required this.body,
    this.drawer,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              snap: true,
              toolbarHeight: 56,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              title: header,
            ),
          ];
        },
        body: body,
      ),
    );
  }
}
