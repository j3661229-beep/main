import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/farm_tools.dart';
import '../theme/app_colors.dart';

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
    final headerGradient = gradient ?? AppColors.farmerGradient;
    final content = onRefresh != null
        ? RefreshIndicator(color: accent, onRefresh: onRefresh!, child: body)
        : body;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: floatingActionButton,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: subtitle != null || emoji != null ? 148 : 120,
            pinned: true,
            elevation: 0,
            backgroundColor: accent,
            leading: showBack
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => context.canPop() ? context.pop() : null,
                  )
                : const SizedBox(),
            actions: actions,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: headerGradient),
                padding: EdgeInsets.fromLTRB(showBack ? 56 : 20, MediaQuery.of(context).padding.top + 12, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (emoji != null)
                      Text(emoji!, style: const TextStyle(fontSize: 32)),
                    if (emoji != null) const SizedBox(height: 6),
                    Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: content),
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
    return Material(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
            boxShadow: AppColors.softShadow,
          ),
          child: Padding(padding: padding, child: child),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tint, tint.withValues(alpha: 0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 13, color: accent, height: 1.45, fontWeight: FontWeight.w500),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? AppColors.surface : null,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: gradient != null ? Colors.white.withValues(alpha: 0.2) : tint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: gradient != null ? Colors.white : AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: GoogleFonts.inter(
                fontSize: 11,
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

  const FarmToolTile({super.key, required this.tool, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(tool.route),
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: compact ? 40 : 44,
              height: compact ? 40 : 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [tool.tint, tool.tint.withValues(alpha: 0.4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tool.accent.withValues(alpha: 0.15)),
              ),
              child: Center(child: Text(tool.emoji, style: TextStyle(fontSize: compact ? 20 : 22))),
            ),
            SizedBox(height: compact ? 8 : 10),
            Text(
              tool.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                height: 1.15,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 3),
              Text(
                tool.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.muted),
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

  const FarmToolsBanner({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A3D18), Color(0xFF3D6B35), Color(0xFF5A9247)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.primaryShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '12 TOOLS',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Farm Toolkit',
                    style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Prices, AI, schemes, insurance & more',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}

class FarmToolsGrid extends StatelessWidget {
  final List<FarmToolItem> tools;
  final int crossAxisCount;
  final bool compact;

  const FarmToolsGrid({
    super.key,
    required this.tools,
    this.crossAxisCount = 3,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: compact ? 0.82 : 0.88,
      ),
      itemCount: tools.length,
      itemBuilder: (_, i) => FarmToolTile(tool: tools[i], compact: compact),
    );
  }
}

class WeatherHeroCard extends StatelessWidget {
  final Map weather;
  final VoidCallback? onTap;

  const WeatherHeroCard({super.key, required this.weather, this.onTap});

  @override
  Widget build(BuildContext context) {
    final temp = weather['temperature'] ?? weather['temp'] ?? (weather['main'] as Map?)?['temp'] ?? '--';
    final desc = weather['description'] ?? weather['condition'] ?? 'Clear';
    final humidity = weather['humidity'] ?? (weather['main'] as Map?)?['humidity'] ?? '--';
    final wind = weather['windSpeed'] ?? weather['wind_speed'] ?? (weather['wind'] as Map?)?['speed'] ?? '--';
    final location = weather['location'] ?? weather['city'] ?? weather['name'] ?? 'Your farm';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A3D18), Color(0xFF3D6B35), Color(0xFF6B9B5A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
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
                      Icon(Icons.location_on_rounded, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                      const SizedBox(width: 4),
                      Text(location, style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('$temp°', style: GoogleFonts.spaceGrotesk(fontSize: 48, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
                  Text(desc.toString(), style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.9))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _WeatherStat(icon: Icons.water_drop_outlined, value: '$humidity%'),
                      const SizedBox(width: 16),
                      _WeatherStat(icon: Icons.air_rounded, value: '${wind}km/h'),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                const Text('🌤️', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Advisory →', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
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
  const _WeatherStat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 14),
        const SizedBox(width: 4),
        Text(value, style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w500)),
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
    return AgriCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
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
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? accent.withValues(alpha: 0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(active ? item.activeIcon : item.icon, color: active ? accent : AppColors.muted, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
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
