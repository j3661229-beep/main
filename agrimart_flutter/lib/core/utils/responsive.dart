import 'package:flutter/material.dart';

/// Breakpoints aligned with Material adaptive layout.
enum ScreenSize {
  compact,  // phone portrait  < 600
  medium,   // large phone / small tablet 600–839
  expanded, // tablet 840–1199
  large,    // desktop / wide tablet >= 1200
}

/// Design reference width (typical phone).
const double _designWidth = 390.0;

class Responsive {
  Responsive(this.context);

  final BuildContext context;

  Size get size => MediaQuery.sizeOf(context);
  double get width => size.width;
  double get height => size.height;
  EdgeInsets get safePadding => MediaQuery.paddingOf(context);
  Orientation get orientation => MediaQuery.orientationOf(context);

  ScreenSize get screenSize {
    if (width >= 1200) return ScreenSize.large;
    if (width >= 840) return ScreenSize.expanded;
    if (width >= 600) return ScreenSize.medium;
    return ScreenSize.compact;
  }

  bool get isCompact => screenSize == ScreenSize.compact;
  bool get isMedium => screenSize == ScreenSize.medium;
  bool get isExpanded => screenSize == ScreenSize.expanded;
  bool get isLarge => screenSize == ScreenSize.large;
  bool get isTablet => width >= 600;
  bool get isWide => width >= 840;
  bool get isLandscape => orientation == Orientation.landscape;

  /// Scale factor clamped so UI never breaks on tiny or huge screens.
  double get scale {
    final raw = width / _designWidth;
    if (isCompact) return raw.clamp(0.82, 1.12);
    if (isMedium) return raw.clamp(0.95, 1.2);
    return raw.clamp(1.0, 1.35);
  }

  /// Responsive font / icon size.
  double sp(double value) => value * scale;

  /// Responsive spacing, radius, icon box, etc.
  double rs(double value) => value * scale;

  /// Max content width — keeps tablet layouts readable.
  double get maxContentWidth {
    switch (screenSize) {
      case ScreenSize.large:
        return 960;
      case ScreenSize.expanded:
        return 840;
      case ScreenSize.medium:
        return 720;
      case ScreenSize.compact:
        return width;
    }
  }

  double get horizontalPadding {
    if (isLarge) return rs(32);
    if (isExpanded) return rs(28);
    if (isMedium) return rs(24);
    return rs(16);
  }

  EdgeInsets get pagePadding => EdgeInsets.symmetric(horizontal: horizontalPadding);

  EdgeInsets get pagePaddingAll => EdgeInsets.all(horizontalPadding);

  /// Bottom inset for floating nav bars.
  double get bottomNavInset {
    if (isTablet) return rs(100);
    return rs(88);
  }

  int gridColumns({int compact = 2, int medium = 3, int expanded = 4, int large = 4}) {
    switch (screenSize) {
      case ScreenSize.large:
        return large;
      case ScreenSize.expanded:
        return expanded;
      case ScreenSize.medium:
        return medium;
      case ScreenSize.compact:
        return isLandscape ? medium : compact;
    }
  }

  int toolGridColumns() => gridColumns(compact: 3, medium: 4, expanded: 5, large: 6);

  int quickActionColumns() => gridColumns(compact: 2, medium: 2, expanded: 4, large: 4);

  double get appBarExpandedHeight {
    if (isWide) return rs(180);
    if (isTablet) return rs(168);
    return rs(148);
  }

  double get heroHeaderHeight {
    if (isWide) return rs(200);
    if (isTablet) return rs(180);
    return rs(168);
  }

  SliverGridDelegate productGridDelegate() => SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns(compact: 2, medium: 3, expanded: 4, large: 5),
        crossAxisSpacing: rs(12),
        mainAxisSpacing: rs(12),
        childAspectRatio: isTablet ? 0.82 : 0.76,
      );

  SliverGridDelegate toolGridDelegate({bool compact = false}) =>
      SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compact ? toolGridColumns() : toolGridColumns(),
        crossAxisSpacing: rs(10),
        mainAxisSpacing: rs(10),
        childAspectRatio: compact ? (isTablet ? 0.9 : 0.82) : (isTablet ? 0.95 : 0.88),
      );

  SliverGridDelegate quickActionGridDelegate() => SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: quickActionColumns(),
        crossAxisSpacing: rs(12),
        mainAxisSpacing: rs(12),
        childAspectRatio: isTablet ? 1.5 : 1.35,
      );

  double valueFor<T>({required T compact, T? medium, T? expanded, T? large}) {
    switch (screenSize) {
      case ScreenSize.large:
        return (large ?? expanded ?? medium ?? compact) as double;
      case ScreenSize.expanded:
        return (expanded ?? medium ?? compact) as double;
      case ScreenSize.medium:
        return (medium ?? compact) as double;
      case ScreenSize.compact:
        return compact as double;
    }
  }
}

extension ResponsiveContext on BuildContext {
  Responsive get r => Responsive(this);
}

/// Centers content and caps width on tablets / desktops.
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool applyPadding;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.padding,
    this.applyPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: r.maxContentWidth),
        child: applyPadding
            ? Padding(
                padding: padding ?? r.pagePadding,
                child: child,
              )
            : child,
      ),
    );
  }
}

/// Responsive horizontal padding only (full-bleed backgrounds still work).
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool constrainWidth;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.padding,
    this.constrainWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final content = Padding(
      padding: padding ?? r.pagePadding,
      child: child,
    );
    if (!constrainWidth || r.isCompact) return content;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: r.maxContentWidth),
        child: content,
      ),
    );
  }
}

/// Build different layouts per breakpoint.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSize size, Responsive r) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return builder(context, r.screenSize, r);
  }
}
