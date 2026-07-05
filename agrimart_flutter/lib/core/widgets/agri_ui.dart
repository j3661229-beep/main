import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/farm_tools.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';

// ── Premium screen shell ────────────────────────────────────

class AgriScreen extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? emoji;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Future<void> Function()? onRefresh;
  final Color accent;
  final LinearGradient? gradient;
  final bool showBack;

  const AgriScreen({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.emoji,
    this.actions,
    this.floatingActionButton,
    this.onRefresh,
    this.accent = AppColors.farmerAccent,
    this.gradient,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final headerGradient = gradient ?? AppColors.farmerGradient;
    final expandedH = subtitle != null || emoji != null ? r.rs(148) : r.rs(120);
    final content = onRefresh != null
        ? RefreshIndicator(color: accent, onRefresh: onRefresh!, child: body)
        : body;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: floatingActionButton,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: expandedH,
            pinned: true,
            elevation: 0,
            backgroundColor: accent,
            leading: showBack
                ? IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: Colors.white, size: r.rs(24)),
                    onPressed: () => context.canPop() ? context.pop() : null,
                  )
                : const SizedBox(),
            actions: actions,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: headerGradient),
                padding: EdgeInsets.fromLTRB(
                  showBack ? r.rs(56) : r.horizontalPadding,
                  r.safePadding.top + r.rs(12),
                  r.horizontalPadding,
                  r.rs(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (emoji != null)
                      Text(emoji!, style: TextStyle(fontSize: r.sp(32))),
                    if (emoji != null) SizedBox(height: r.rs(6)),
                    Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: r.sp(24),
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: r.rs(4)),
                      Text(
                        subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: r.sp(13),
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ResponsiveLayout(applyPadding: false, child: content),
          ),
        ],
      ),
    );
  }
}

// ── Cards & tiles ───────────────────────────────────────────

class AgriCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  const AgriCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Material(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(r.rs(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r.rs(18)),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r.rs(18)),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
            boxShadow: AppColors.softShadow,
          ),
          child: Padding(
            padding: padding == const EdgeInsets.all(16)
                ? EdgeInsets.all(r.rs(16))
                : padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  final String text;
  final Color accent;
  final Color tint;
  final IconData icon;

  const InfoBanner({
    super.key,
    required this.text,
    this.accent = AppColors.farmerAccent,
    this.tint = AppColors.farmerTint,
    this.icon = Icons.info_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: EdgeInsets.all(r.rs(16)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tint, tint.withValues(alpha: 0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(r.rs(16)),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: r.rs(36),
            height: r.rs(36),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(r.rs(10))),
            child: Icon(icon, color: accent, size: r.rs(20)),
          ),
          SizedBox(width: r.rs(12)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: r.sp(13), color: accent, height: 1.45, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class QuickActionTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String sublabel;
  final Color accent;
  final Color tint;
  final VoidCallback onTap;
  final LinearGradient? gradient;

  const QuickActionTile({
    super.key,
    required this.emoji,
    required this.label,
    required this.sublabel,
    required this.accent,
    required this.tint,
    required this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(r.rs(16)),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? AppColors.surface : null,
          borderRadius: BorderRadius.circular(r.rs(18)),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: r.rs(42),
              height: r.rs(42),
              decoration: BoxDecoration(
                color: gradient != null ? Colors.white.withValues(alpha: 0.2) : tint,
                borderRadius: BorderRadius.circular(r.rs(12)),
              ),
              child: Center(child: Text(emoji, style: TextStyle(fontSize: r.sp(22)))),
            ),
            SizedBox(height: r.rs(10)),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: r.sp(14),
                fontWeight: FontWeight.w700,
                color: gradient != null ? Colors.white : AppColors.ink,
              ),
            ),
            SizedBox(height: r.rs(2)),
            Text(
              sublabel,
              style: GoogleFonts.inter(
                fontSize: r.sp(11),
                color: gradient != null ? Colors.white.withValues(alpha: 0.85) : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FarmToolTile extends StatelessWidget {
  final FarmToolItem tool;
  final bool compact;
  final String? displayLabel;
  final String? displaySubtitle;
  final VoidCallback? onTap;

  const FarmToolTile({
    super.key,
    required this.tool,
    this.compact = false,
    this.displayLabel,
    this.displaySubtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final iconSize = compact ? r.rs(40) : r.rs(44);
    final label = displayLabel ?? tool.label;
    final subtitle = displaySubtitle ?? tool.subtitle;
    return GestureDetector(
      onTap: onTap ?? () => context.push(tool.route),
      child: Container(
        padding: EdgeInsets.all(compact ? r.rs(12) : r.rs(14)),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(r.rs(18)),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [tool.tint, tool.tint.withValues(alpha: 0.4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(r.rs(14)),
                border: Border.all(color: tool.accent.withValues(alpha: 0.15)),
              ),
              child: Center(child: Text(tool.emoji, style: TextStyle(fontSize: compact ? r.sp(20) : r.sp(22)))),
            ),
            SizedBox(height: compact ? r.rs(8) : r.rs(10)),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: compact ? r.sp(12) : r.sp(13),
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                height: 1.15,
              ),
            ),
            if (!compact) ...[
              SizedBox(height: r.rs(3)),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: r.sp(10), color: AppColors.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FarmToolsBanner extends StatelessWidget {
  final VoidCallback onTap;
  final String? badgeText;
  final String? title;
  final String? subtitle;

  const FarmToolsBanner({
    super.key,
    required this.onTap,
    this.badgeText,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(r.rs(18)),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A3D18), Color(0xFF3D6B35), Color(0xFF5A9247)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(r.rs(20)),
          boxShadow: AppColors.primaryShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: r.rs(10), vertical: r.rs(4)),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(r.rs(20)),
                    ),
                    child: Text(
                      badgeText ?? '12 TOOLS',
                      style: GoogleFonts.inter(fontSize: r.sp(10), fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1),
                    ),
                  ),
                  SizedBox(height: r.rs(10)),
                  Text(
                    title ?? 'Farm Toolkit',
                    style: GoogleFonts.spaceGrotesk(fontSize: r.sp(22), fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  SizedBox(height: r.rs(4)),
                  Text(
                    subtitle ?? 'Prices, AI, schemes, insurance & more',
                    style: GoogleFonts.inter(fontSize: r.sp(12), color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
            Container(
              width: r.rs(56),
              height: r.rs(56),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(r.rs(16)),
              ),
              child: Icon(Icons.grid_view_rounded, color: Colors.white, size: r.rs(28)),
            ),
          ],
        ),
      ),
    );
  }
}

class FarmToolsGrid extends StatelessWidget {
  final List<FarmToolItem> tools;
  final int? crossAxisCount;
  final bool compact;
  final String Function(FarmToolItem)? labelFor;
  final String Function(FarmToolItem)? subtitleFor;
  final void Function(FarmToolItem)? onToolTap;

  const FarmToolsGrid({
    super.key,
    required this.tools,
    this.crossAxisCount,
    this.compact = false,
    this.labelFor,
    this.subtitleFor,
    this.onToolTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final cols = crossAxisCount ?? r.toolGridColumns();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: r.rs(10),
        crossAxisSpacing: r.rs(10),
        childAspectRatio: compact ? (r.isTablet ? 0.9 : 0.82) : (r.isTablet ? 0.95 : 0.88),
      ),
      itemCount: tools.length,
      itemBuilder: (_, i) {
        final tool = tools[i];
        return FarmToolTile(
          tool: tool,
          compact: compact,
          displayLabel: labelFor?.call(tool),
          displaySubtitle: subtitleFor?.call(tool),
          onTap: onToolTap != null ? () => onToolTap!(tool) : null,
        );
      },
    );
  }
}

class WeatherHeroCard extends StatelessWidget {
  final Map weather;
  final VoidCallback? onTap;

  const WeatherHeroCard({super.key, required this.weather, this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final temp = weather['temperature'] ?? weather['temp'] ?? (weather['main'] as Map?)?['temp'] ?? '--';
    final desc = weather['description'] ?? weather['condition'] ?? 'Clear';
    final humidity = weather['humidity'] ?? (weather['main'] as Map?)?['humidity'] ?? '--';
    final wind = weather['windSpeed'] ?? weather['wind_speed'] ?? (weather['wind'] as Map?)?['speed'] ?? '--';
    final location = weather['location'] ?? weather['city'] ?? weather['name'] ?? 'Your farm';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(r.rs(20)),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A3D18), Color(0xFF3D6B35), Color(0xFF6B9B5A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(r.rs(22)),
          boxShadow: AppColors.primaryShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: r.rs(14), color: Colors.white.withValues(alpha: 0.8)),
                      SizedBox(width: r.rs(4)),
                      Flexible(
                        child: Text(
                          location.toString(),
                          style: GoogleFonts.inter(fontSize: r.sp(12), color: Colors.white.withValues(alpha: 0.85)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: r.rs(8)),
                  Text('$temp°', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(48), fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
                  Text(desc.toString(), style: GoogleFonts.inter(fontSize: r.sp(14), color: Colors.white.withValues(alpha: 0.9))),
                  SizedBox(height: r.rs(12)),
                  Row(
                    children: [
                      _WeatherStat(icon: Icons.water_drop_outlined, value: '$humidity%', size: r.rs(14)),
                      SizedBox(width: r.rs(16)),
                      _WeatherStat(icon: Icons.air_rounded, value: '${wind}km/h', size: r.rs(14)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text('🌤️', style: TextStyle(fontSize: r.sp(56))),
                SizedBox(height: r.rs(8)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: r.rs(10), vertical: r.rs(5)),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(r.rs(20)),
                  ),
                  child: Text('Advisory →', style: GoogleFonts.inter(fontSize: r.sp(11), fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final double size;
  const _WeatherStat({required this.icon, required this.value, required this.size});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: size),
        SizedBox(width: r.rs(4)),
        Text(value, style: GoogleFonts.inter(fontSize: r.sp(12), color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class AgriListTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color accent;
  final Color tint;

  const AgriListTile({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.accent = AppColors.farmerAccent,
    this.tint = AppColors.farmerTint,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AgriCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(horizontal: r.rs(14), vertical: r.rs(12)),
      child: Row(
        children: [
          Container(
            width: r.rs(48),
            height: r.rs(48),
            decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(r.rs(14))),
            child: Center(child: Text(emoji, style: TextStyle(fontSize: r.sp(24)))),
          ),
          SizedBox(width: r.rs(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: r.sp(15), fontWeight: FontWeight.w600, color: AppColors.ink)),
                SizedBox(height: r.rs(2)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted)),
              ],
            ),
          ),
          trailing ?? Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: r.rs(22)),
        ],
      ),
    );
  }
}

// ── Bottom navigation ───────────────────────────────────────

class RoleBottomNav extends StatelessWidget {
  final int currentIndex;
  final Color accent;
  final ValueChanged<int> onTap;
  final List<RoleNavItem> items;

  const RoleBottomNav({
    super.key,
    required this.currentIndex,
    required this.accent,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      margin: EdgeInsets.fromLTRB(r.horizontalPadding, 0, r.horizontalPadding, r.rs(12)),
      padding: EdgeInsets.symmetric(horizontal: r.rs(6), vertical: r.rs(8)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r.rs(24)),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: AppColors.deepShadow,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final item = items[i];
            final active = i == currentIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  margin: EdgeInsets.symmetric(horizontal: r.rs(2)),
                  padding: EdgeInsets.symmetric(vertical: r.rs(8)),
                  decoration: BoxDecoration(
                    color: active ? accent.withValues(alpha: 0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(r.rs(16)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(active ? item.activeIcon : item.icon, color: active ? accent : AppColors.muted, size: r.rs(22)),
                      SizedBox(height: r.rs(4)),
                      Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: r.sp(10),
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? accent : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class RoleNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const RoleNavItem({required this.icon, required this.activeIcon, required this.label});
}
