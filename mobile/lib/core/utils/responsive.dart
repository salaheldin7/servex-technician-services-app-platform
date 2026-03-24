import 'package:flutter/material.dart';

/// Responsive breakpoints and utilities for adaptive layouts across
/// phones, phablets, tablets, and landscape orientations.
class Responsive {
  Responsive._();

  // ─── Breakpoints ───────────────────────────────────────────
  static const double _mobileBreak = 600;
  static const double _tabletBreak = 900;
  static const double _desktopBreak = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < _mobileBreak;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= _mobileBreak && w < _desktopBreak;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= _desktopBreak;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  // ─── Sizing helpers ────────────────────────────────────────

  /// Percentage of screen width (0‑1 fraction).
  static double wp(BuildContext context, double fraction) =>
      MediaQuery.sizeOf(context).width * fraction;

  /// Percentage of screen height (0‑1 fraction).
  static double hp(BuildContext context, double fraction) =>
      MediaQuery.sizeOf(context).height * fraction;

  /// Returns a value picked by current breakpoint.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= _desktopBreak) return desktop ?? tablet ?? mobile;
    if (w >= _mobileBreak) return tablet ?? mobile;
    return mobile;
  }

  // ─── Padding / Spacing ─────────────────────────────────────

  /// Horizontal page padding – grows with screen width.
  static double horizontalPadding(BuildContext context) =>
      value(context, mobile: 16.0, tablet: 24.0, desktop: 32.0);

  /// Vertical spacing between sections.
  static double sectionSpacing(BuildContext context) =>
      value(context, mobile: 16.0, tablet: 24.0, desktop: 32.0);

  /// Symmetric page EdgeInsets that adapts.
  static EdgeInsets pagePadding(BuildContext context) {
    final h = horizontalPadding(context);
    return EdgeInsets.symmetric(horizontal: h, vertical: h);
  }

  // ─── Grid helpers ──────────────────────────────────────────

  /// Adaptive cross‑axis count for category / card grids.
  static int gridColumns(
    BuildContext context, {
    int mobile = 2,
    int mobileLandscape = 3,
    int tablet = 4,
    int desktop = 6,
  }) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= _desktopBreak) return desktop;
    if (w >= _tabletBreak) return tablet;
    if (w >= _mobileBreak) return mobileLandscape;
    if (isLandscape(context)) return mobileLandscape;
    return mobile;
  }

  /// Max content width — keeps forms/details readable on wide screens.
  static double maxFormWidth(BuildContext context) =>
      value(context, mobile: double.infinity, tablet: 520.0, desktop: 560.0);

  static double maxContentWidth(BuildContext context) =>
      value(context, mobile: double.infinity, tablet: 700.0, desktop: 800.0);

  // ─── Font scale ────────────────────────────────────────────

  /// A slight font boost on bigger displays (1.0 on phones).
  static double fontScale(BuildContext context) =>
      value(context, mobile: 1.0, tablet: 1.05, desktop: 1.1);

  // ─── Icon / element sizing ─────────────────────────────────

  static double iconSize(BuildContext context,
          {double mobile = 24, double? tablet, double? desktop}) =>
      value(context, mobile: mobile, tablet: tablet, desktop: desktop);

  /// Returns side of a square that fits N columns with given spacing.
  static double tileSize(BuildContext context,
      {int columns = 4, double spacing = 12}) {
    final available =
        MediaQuery.sizeOf(context).width - horizontalPadding(context) * 2;
    return (available - spacing * (columns - 1)) / columns;
  }

  // ─── Navigation ────────────────────────────────────────────

  /// Whether we should show NavigationRail instead of BottomNavBar.
  static bool useNavigationRail(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= _mobileBreak;
}

/// A convenience widget that centers its child with a max‑width constraint.
/// On phones it just applies padding; on tablets/desktop it also constrains.
class ResponsiveCenter extends StatelessWidget {
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  const ResponsiveCenter({
    super.key,
    this.maxWidth,
    this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMax = maxWidth ?? Responsive.maxFormWidth(context);
    final effectivePadding =
        padding ?? Responsive.pagePadding(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMax),
        child: Padding(
          padding: effectivePadding,
          child: child,
        ),
      ),
    );
  }
}

/// Builds different layouts for mobile vs wider (tablet/desktop) screens.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context) && desktop != null) {
      return desktop!(context);
    }
    if (!Responsive.isMobile(context) && tablet != null) {
      return tablet!(context);
    }
    return mobile(context);
  }
}

/// A SliverGridDelegate that picks column count adaptively.
class ResponsiveGridDelegate extends SliverGridDelegateWithFixedCrossAxisCount {
  ResponsiveGridDelegate(
    BuildContext context, {
    int mobile = 2,
    int mobileLandscape = 3,
    int tablet = 4,
    int desktop = 6,
    super.crossAxisSpacing = 12,
    super.mainAxisSpacing = 12,
    super.childAspectRatio = 1.0,
  }) : super(
          crossAxisCount: Responsive.gridColumns(
            context,
            mobile: mobile,
            mobileLandscape: mobileLandscape,
            tablet: tablet,
            desktop: desktop,
          ),
        );
}
