import 'package:flutter/material.dart';

/// Scroll behavior bawaan aplikasi:
/// - Tanpa indikator overscroll (glow/stretch) supaya konten diam saat
///   menyentuh batas atas/bawah.
/// - ClampingScrollPhysics supaya tidak memantul (bounce) di platform apa pun.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}
