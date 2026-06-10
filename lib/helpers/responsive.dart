import 'package:flutter/material.dart';

class Responsive {
  static const double _tablet = 600;
  static const double _desktop = 900;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= _tablet;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= _desktop;

  static double posterWidth(BuildContext context) =>
      isTablet(context) ? 160 : 132;

  static double gridMaxExtent(BuildContext context) =>
      isTablet(context) ? 240 : 190;

  static double gridAspectRatio(BuildContext context) =>
      isTablet(context) ? 0.60 : 0.52;

  static EdgeInsets screenPadding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= _desktop) return const EdgeInsets.symmetric(horizontal: 48);
    if (w >= _tablet) return const EdgeInsets.symmetric(horizontal: 32);
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  static double maxContentWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w > 1200 ? 1200 : w;
  }
}
