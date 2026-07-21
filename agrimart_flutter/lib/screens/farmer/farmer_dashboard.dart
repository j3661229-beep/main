import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:agrimart/l10n/app_localizations.dart';
import '../../../core/constants/farm_tools.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/agri_ui.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/utils/farm_tool_l10n.dart';
import '../../../core/utils/farm_profile_utils.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/app_providers.dart';
import '../../../data/providers/youtube_provider.dart';

class FarmerDashboard extends ConsumerStatefulWidget {
  const FarmerDashboard({super.key});
  @override
  ConsumerState<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends ConsumerState<FarmerDashboard>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollCtrl;
  late final ValueNotifier<double> _headerOpacity;

  @override
  void initState() {
    super.initState();
    _headerOpacity = ValueNotifier(0);
    _scrollCtrl = ScrollController();
    _scrollCtrl.addListener(() {
      final opacity = (_scrollCtrl.offset / 80).clamp(0.0, 1.0);
      if ((opacity - _headerOpacity.value).abs() > 0.02) {
        _headerOpacity.value = opacity;
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _headerOpacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final name = user?.name ?? 'Kisan';
    final district = user?.effectiveDistrict ?? 'Nashik';
    final weather = ref.watch(weatherProvider);
    final featuredTools = featuredFarmTools();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.farmerAccent,
        onRefresh: () async {
          ref.invalidate(weatherProvider);
          ref.invalidate(farmerDashboardProvider);
          ref.invalidate(mandiNewsProvider);
          ref.invalidate(mandiTickerProvider);
          ref.invalidate(weatherAdvisoryProvider(district));
        },
        child: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            // ── Hero Header ──────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: r.heroHeaderHeight + 20,
              pinned: true,
              backgroundColor: AppColors.farmerAccent,
              leading: const SizedBox(),
              title: ValueListenableBuilder<double>(
                valueListenable: _headerOpacity,
                builder: (_, opacity, __) => AnimatedOpacity(
                  opacity: opacity,
                  duration: const Duration(milliseconds: 150),
                  child: Text(
                    'AgriMart',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: r.sp(18),
                    ),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: _HeroHeader(name: name, district: district, r: r),
              ),
            ),

            SliverToBoxAdapter(
              child: ResponsiveLayout(
                applyPadding: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      r.horizontalPadding, 0, r.horizontalPadding, r.bottomNavInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const OfflineBanner(),

                      // ── Weather Card ─────────────────────────────────
                      FadeInUp(
                        duration: const Duration(milliseconds: 400),
                        child: Padding(
                          padding: EdgeInsets.only(top: r.rs(16)),
                          child: weather.when(
                            loading: () => const ShimmerBox(height: 130, radius: 22),
                            error: (_, __) => _WeatherError(l10n: l10n),
                            data: (w) => WeatherHeroCard(
                              weather: w,
                              onTap: () => context.push('/farmer/advisory'),
                            ),
                          ),
                        ),
                      ),

                      // ── Advisory Strip ───────────────────────────────
                      FadeInUp(
                        delay: const Duration(milliseconds: 60),
                        child: Padding(
                          padding: EdgeInsets.only(top: r.rs(10)),
                          child: _AdvisoryStrip(district: district),
                        ),
                      ),

                      // ── Live Mandi Ticker ────────────────────────────
                      FadeInUp(
                        delay: const Duration(milliseconds: 80),
                        child: Padding(
                          padding: EdgeInsets.only(top: r.rs(10)),
                          child: _MandiTicker(district: district),
                        ),
                      ),

                      SizedBox(height: r.rs(28)),

                      // ── Quick Actions ────────────────────────────────
                      FadeInUp(
                        delay: const Duration(milliseconds: 100),
                        child: _SectionHeader(
                          title: l10n.quickActions,
                          icon: Icons.grid_view_rounded,
                        ),
                      ),
                      SizedBox(height: r.rs(14)),
                      FadeInUp(
                        delay: const Duration(milliseconds: 120),
                        child: _QuickActionsGrid(l10n: l10n),
                      ),

                      SizedBox(height: r.rs(28)),

                      // ── AI Feature Spotlight ─────────────────────────
                      FadeInUp(
                        delay: const Duration(milliseconds: 130),
                        child: _AISpotlightBanner(),
                      ),

                      SizedBox(height: r.rs(28)),

                      // ── Farm Tools ───────────────────────────────────
                      FadeInUp(
                        delay: const Duration(milliseconds: 140),
                        child: FarmToolsBanner(
                          onTap: () => context.push('/farmer/tools'),
                          badgeText: l10n.toolsCount(kFarmTools.length),
                          title: l10n.farmToolkit,
                          subtitle: l10n.farmToolkitCardSubtitle,
                        ),
                      ),
                      SizedBox(height: r.rs(16)),
                      FadeInUp(
                        delay: const Duration(milliseconds: 155),
                        child: _SectionHeader(
                          title: l10n.popularTools,
                          icon: Icons.build_rounded,
                          trailing: _SeeAllChip(
                            onTap: () => context.push('/farmer/tools'),
                            label: l10n.seeAll,
                          ),
                        ),
                      ),
                      SizedBox(height: r.rs(12)),
                      FadeInUp(
                        delay: const Duration(milliseconds: 160),
                        child: FarmToolsGrid(
                          tools: featuredTools,
                          compact: true,
                          labelFor: (t) => farmToolLabelL10n(l10n, t),
                          subtitleFor: (t) => farmToolSubtitleL10n(l10n, t),
                        ),
                      ),

                      SizedBox(height: r.rs(28)),

                      // ── Mandi News ───────────────────────────────────
                      FadeInUp(
                        delay: const Duration(milliseconds: 175),
                        child: _MandiNewsSection(
                          district: user?.effectiveDistrict,
                          onViewAll: () => context.push('/farmer/news'),
                        ),
                      ),

                      SizedBox(height: r.rs(28)),

                      // ── Krishi TV ────────────────────────────────────
                      FadeInUp(
                        delay: const Duration(milliseconds: 190),
                        child: _WatchLearnSection(
                          onViewAll: () => context.push('/farmer/krishi-tv'),
                          onVideoTap: (video) => context.push(
                            '/farmer/video-player',
                            extra: {
                              'videoId': video['videoId'],
                              'title': video['title'],
                              'channel': video['channel'],
                              'thumbnailUrl': video['thumbnail'],
                            },
                          ),
                        ),
                      ),

                      SizedBox(height: r.rs(20)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero Header ───────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final String name, district;
  final Responsive r;
  const _HeroHeader({required this.name, required this.district, required this.r});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Deep gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A3018), Color(0xFF2E5728), Color(0xFF4A8040)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // Decorative circles
        Positioned(
          right: -40, top: -40,
          child: Container(
            width: r.rs(220), height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        ),
        Positioned(
          left: -30, bottom: -60,
          child: Container(
            width: r.rs(180), height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.03),
            ),
          ),
        ),

        // Grain emoji watermark
        Positioned(
          right: r.rs(10),
          top: r.rs(24),
          child: Opacity(
            opacity: 0.07,
            child: Text('🌾', style: TextStyle(fontSize: r.sp(130))),
          ),
        ),

        // Content
        Padding(
          padding: EdgeInsets.fromLTRB(
            r.horizontalPadding,
            r.safePadding.top + r.rs(14),
            r.horizontalPadding,
            r.rs(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Morning greeting pill
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: r.rs(10), vertical: r.rh(4)),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(r.rs(20)),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🙏', style: TextStyle(fontSize: r.sp(11))),
                              SizedBox(width: r.rs(5)),
                              Text(
                                _greeting(),
                                style: GoogleFonts.inter(
                                  fontSize: r.sp(11),
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: r.rs(8)),
                        Text(
                          name,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: r.sp(28),
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: r.rs(4)),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                size: r.rs(13), color: Colors.white.withValues(alpha: 0.7)),
                            SizedBox(width: r.rs(3)),
                            Text(
                              district,
                              style: GoogleFonts.inter(
                                fontSize: r.sp(12),
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            SizedBox(width: r.rs(10)),
                            Container(
                              width: r.rs(3), height: 3,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: r.rs(10)),
                            Text(
                              _season(),
                              style: GoogleFonts.inter(
                                fontSize: r.sp(12),
                                color: const Color(0xFF90C97A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Notification bell
                  Builder(builder: (ctx) => _HeaderIconButton(
                    icon: Icons.notifications_outlined,
                    onTap: () => ctx.push('/notifications'),
                  )),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _season() {
    final m = DateTime.now().month;
    if (m >= 6 && m <= 10) return '🌧 Kharif Season';
    if (m >= 11 || m <= 2) return '☀️ Rabi Season';
    return '🌸 Zaid Season';
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  const _SectionHeader({required this.title, required this.icon, this.trailing});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Row(
      children: [
        Container(
          width: r.rs(32), height: r.rs(32),
          decoration: BoxDecoration(
            color: AppColors.farmerTint,
            borderRadius: BorderRadius.circular(r.rs(9)),
          ),
          child: Icon(icon, color: AppColors.farmerAccent, size: r.rs(17)),
        ),
        SizedBox(width: r.rs(10)),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: r.sp(18),
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── See All Chip ──────────────────────────────────────────────────────────────
class _SeeAllChip extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _SeeAllChip({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: r.rs(12), vertical: r.rh(6)),
        decoration: BoxDecoration(
          color: AppColors.farmerTint,
          borderRadius: BorderRadius.circular(r.rs(20)),
          border: Border.all(color: AppColors.farmerAccent.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
              style: GoogleFonts.inter(
                fontSize: r.sp(12), fontWeight: FontWeight.w600, color: AppColors.farmerAccent)),
            SizedBox(width: r.rs(3)),
            Icon(Icons.arrow_forward_rounded, color: AppColors.farmerAccent, size: r.sp(13)),
          ],
        ),
      ),
    );
  }
}

// ── Quick Actions Grid — redesigned ──────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  final AppLocalizations l10n;
  const _QuickActionsGrid({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final actions = [
      _ActionItem(
        emoji: '🔬', label: l10n.scanCrop, sub: l10n.aiDiagnosis,
        gradient: const LinearGradient(colors: [Color(0xFF1B3A18), Color(0xFF3D7A35)]),
        route: '/farmer/diagnose',
      ),
      _ActionItem(
        emoji: '🤖', label: 'Kisan AI', sub: 'Ask anything',
        gradient: const LinearGradient(colors: [Color(0xFF0D2E40), Color(0xFF1A6080)]),
        route: '/farmer/kisan-ai',
      ),
      _ActionItem(
        emoji: '📊', label: 'Mandi Rates', sub: 'Live prices',
        gradient: const LinearGradient(colors: [Color(0xFF6B3A10), Color(0xFFB86020)]),
        route: '/farmer/price-alerts',
      ),
      _ActionItem(
        emoji: '🌤️', label: 'Advisory', sub: 'Farm tips today',
        gradient: const LinearGradient(colors: [Color(0xFF1A4060), Color(0xFF2E6E90)]),
        route: '/farmer/advisory',
      ),
      _ActionItem(
        emoji: '📺', label: 'Krishi TV', sub: 'Farm videos',
        gradient: const LinearGradient(colors: [Color(0xFF7A0000), Color(0xFFCC2020)]),
        route: '/farmer/krishi-tv',
      ),
      _ActionItem(
        emoji: '🏛️', label: 'Schemes', sub: 'Govt benefits',
        gradient: const LinearGradient(colors: [Color(0xFF2E5018), Color(0xFF5A9030)]),
        route: '/farmer/schemes',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: r.rs(10),
        crossAxisSpacing: r.rs(10),
        childAspectRatio: r.isTablet ? 1.6 : 1.05,
      ),
      itemCount: actions.length,
      itemBuilder: (context, i) => _ActionCard(item: actions[i]),
    );
  }
}

class _ActionItem {
  final String emoji, label, sub, route;
  final LinearGradient gradient;
  const _ActionItem({
    required this.emoji, required this.label, required this.sub,
    required this.gradient, required this.route,
  });
}

class _ActionCard extends StatefulWidget {
  final _ActionItem item;
  const _ActionCard({required this.item});
  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); context.push(widget.item.route); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: EdgeInsets.all(r.rs(13)),
          decoration: BoxDecoration(
            gradient: widget.item.gradient,
            borderRadius: BorderRadius.circular(r.rs(18)),
            boxShadow: [
              BoxShadow(
                color: widget.item.gradient.colors.last.withValues(alpha: 0.35),
                blurRadius: r.rs(12),
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Emoji in frosted circle
              Container(
                width: r.rs(36), height: r.rs(36),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(r.rs(10)),
                ),
                child: Center(
                  child: Text(widget.item.emoji, style: TextStyle(fontSize: r.sp(19))),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.label,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: r.sp(12.5),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: r.rh(1.2),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: r.rs(1)),
                  Text(
                    widget.item.sub,
                    style: GoogleFonts.inter(
                      fontSize: r.sp(10),
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── AI Spotlight Banner ───────────────────────────────────────────────────────
class _AISpotlightBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return GestureDetector(
      onTap: () => context.push('/farmer/kisan-ai'),
      child: Container(
        padding: EdgeInsets.all(r.rs(18)),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D2030), Color(0xFF1A4A6A), Color(0xFF2268A0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(r.rs(22)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A4A6A).withValues(alpha: 0.45),
              blurRadius: r.rs(20),
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // AI avatar
            Container(
              width: r.rs(58), height: r.rs(58),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(r.rs(16)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Center(
                child: Text('🤖', style: TextStyle(fontSize: r.sp(30))),
              ),
            ),
            SizedBox(width: r.rs(16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Kisan AI',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: r.sp(17),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: r.rs(8)),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: r.rs(7), vertical: r.rh(2)),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22D3EE).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(r.rs(8)),
                          border: Border.all(color: const Color(0xFF22D3EE).withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'LIVE',
                          style: GoogleFonts.inter(
                            fontSize: r.sp(9),
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF22D3EE),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: r.rs(4)),
                  Text(
                    'Ask me about crops, disease, mandi prices or schemes — in Hindi, Marathi or English',
                    style: GoogleFonts.inter(
                      fontSize: r.sp(11.5),
                      color: Colors.white.withValues(alpha: 0.75),
                      height: r.rh(1.4),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: r.rs(8)),
            Container(
              width: r.rs(36), height: r.rs(36),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white, size: r.sp(18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header Icon Button ────────────────────────────────────────────────────────
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  const _HeaderIconButton({required this.icon, required this.onTap, this.badge = 0});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(r.rs(14)),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(r.rs(14)),
            child: SizedBox(
              width: r.rs(44),
              height: r.rs(44),
              child: Icon(icon, color: Colors.white, size: r.rs(22)),
            ),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: -2, top: -2,
            child: Container(
              width: r.rs(18), height: r.rs(18),
              decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  '$badge',
                  style: GoogleFonts.inter(
                      fontSize: r.sp(10), fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Weather Error ─────────────────────────────────────────────────────────────
class _WeatherError extends StatelessWidget {
  final AppLocalizations l10n;
  const _WeatherError({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AgriCard(
      child: Row(
        children: [
          Container(
            width: r.rs(44), height: 44,
            decoration: BoxDecoration(
                color: AppColors.farmerTint, borderRadius: BorderRadius.circular(r.rs(12))),
            child: const Icon(Icons.cloud_off_outlined, color: AppColors.muted),
          ),
          SizedBox(width: r.rs(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.weatherUnavailable,
                    style: GoogleFonts.spaceGrotesk(fontSize: r.sp(14), fontWeight: FontWeight.w700)),
                Text(l10n.pullToRefresh,
                    style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Advisory Strip ────────────────────────────────────────────────────────────
class _AdvisoryStrip extends ConsumerWidget {
  final String district;
  const _AdvisoryStrip({required this.district});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final l10n = AppLocalizations.of(context)!;
    final advisory = ref.watch(weatherAdvisoryProvider(district));

    return advisory.when(
      loading: () => const ShimmerBox(height: 60, radius: 16),
      error: (_, __) => const SizedBox.shrink(),
      data: (adv) {
        final list = adv['advisories'] as List?;
        final first = list != null && list.isNotEmpty ? list.first : null;
        final tip = first is Map
            ? (first['body']?.toString().isNotEmpty == true
                ? first['body']?.toString()
                : first['tip']?.toString())
            : first?.toString();
        if (tip == null || tip.isEmpty) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => context.push('/farmer/advisory'),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: r.rs(14), vertical: r.rs(12)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.warning.withValues(alpha: 0.12),
                  AppColors.warningTint,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(r.rs(14)),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: r.rs(36), height: r.rs(36),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(r.rs(10)),
                  ),
                  child: Center(child: Text('🌾', style: TextStyle(fontSize: r.sp(18)))),
                ),
                SizedBox(width: r.rs(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.todaysAdvisory,
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: r.sp(11), fontWeight: FontWeight.w700, color: AppColors.warning)),
                      SizedBox(height: r.rs(2)),
                      Text(tip,
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: r.sp(12), color: AppColors.ink, height: 1.35)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.warning, size: r.rs(20)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Mandi Ticker ──────────────────────────────────────────────────────────────
class _MandiTicker extends ConsumerWidget {
  final String district;
  const _MandiTicker({required this.district});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final l10n = AppLocalizations.of(context)!;
    final ticker = ref.watch(mandiTickerProvider);

    return ticker.when(
      loading: () => const ShimmerBox(height: 56, radius: 14),
      error: (_, __) => const SizedBox.shrink(),
      data: (prices) {
        if (prices.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: r.rs(8), vertical: r.rh(3)),
                  decoration: BoxDecoration(
                    color: AppColors.successTint,
                    borderRadius: BorderRadius.circular(r.rs(8)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up_rounded,
                          size: r.sp(13), color: AppColors.success),
                      SizedBox(width: r.rs(4)),
                      Text(l10n.liveMandiRates,
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: r.sp(12), fontWeight: FontWeight.w700, color: AppColors.success)),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/farmer/price-alerts'),
                  child: Row(
                    children: [
                      Text(l10n.tapForPriceAlerts,
                          style: GoogleFonts.inter(
                              fontSize: r.sp(11), fontWeight: FontWeight.w600,
                              color: AppColors.farmerAccent)),
                      SizedBox(width: r.rs(3)),
                      Icon(Icons.notifications_active_outlined,
                          size: r.sp(13), color: AppColors.farmerAccent),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: r.rs(8)),
            SizedBox(
              height: r.rs(48),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: prices.length,
                separatorBuilder: (_, __) => SizedBox(width: r.rs(8)),
                itemBuilder: (_, i) {
                  final p = prices[i];
                  final crop = p['crop']?.toString() ?? p['commodity']?.toString() ?? 'Crop';
                  final price = p['price'] ?? p['modalPrice'] ?? p['avgPrice'];
                  final emoji = p['emoji']?.toString() ?? '🌾';
                  final trend = p['trend']?.toString();
                  final isUp = trend == 'up';

                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: r.rs(12), vertical: r.rs(8)),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(r.rs(12)),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: Row(
                      children: [
                        Text(emoji, style: TextStyle(fontSize: r.sp(14))),
                        SizedBox(width: r.rs(6)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(crop,
                                style: GoogleFonts.inter(
                                    fontSize: r.sp(10.5), fontWeight: FontWeight.w600,
                                    color: AppColors.muted)),
                            Text(
                              '₹${(price as num?)?.toStringAsFixed(0) ?? '—'}',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: r.sp(12.5), fontWeight: FontWeight.w800,
                                  color: AppColors.ink),
                            ),
                          ],
                        ),
                        SizedBox(width: r.rs(4)),
                        Icon(
                          isUp ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                          color: isUp ? AppColors.success : AppColors.danger,
                          size: r.rs(18),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onShop;
  const _EmptyOrders({required this.l10n, required this.onShop});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AgriCard(
    child: Column(
      children: [
        Text('🛍️', style: TextStyle(fontSize: r.sp(40))),
        SizedBox(height: r.rh(10)),
        Text(l10n.noOrdersYet,
            style: GoogleFonts.spaceGrotesk(fontSize: r.sp(16), fontWeight: FontWeight.w700)),
        SizedBox(height: r.rh(4)),
        Text(l10n.startShoppingInputs,
            style: GoogleFonts.inter(fontSize: r.sp(13), color: AppColors.muted),
            textAlign: TextAlign.center),
        SizedBox(height: r.rh(16)),
        AppButton(label: l10n.browseMarket, onTap: onShop, height: 44, width: 180),
      ],
    ),
  );
  }
}

// ── Mandi News Section ────────────────────────────────────────────────────────
class _MandiNewsSection extends ConsumerWidget {
  final String? district;
  final VoidCallback onViewAll;

  const _MandiNewsSection({required this.district, required this.onViewAll});

  String _timeAgo(String? timestamp) {
    if (timestamp == null) return 'Recently';
    try {
      final diff = DateTime.now().difference(DateTime.parse(timestamp));
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final l10n = AppLocalizations.of(context)!;
    final newsAsync = ref.watch(mandiNewsPreviewProvider);
    final locationLabel = district ?? l10n.home;
    final cardWidth = r.isTablet ? r.rs(320) : r.width * 0.72;
    final listHeight = r.rs(168);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: l10n.mandiNewsSection,
          icon: Icons.newspaper_rounded,
          trailing: _SeeAllChip(onTap: onViewAll, label: l10n.viewAll),
        ),
        SizedBox(height: r.rs(4)),
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: r.rs(13), color: AppColors.farmerAccent),
            SizedBox(width: r.rs(3)),
            Text(l10n.nearLocation(locationLabel),
                style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted)),
          ],
        ),
        SizedBox(height: r.rs(12)),
        newsAsync.when(
          loading: () => SizedBox(
            height: listHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => SizedBox(width: r.rs(12)),
              itemBuilder: (_, __) =>
                  ShimmerBox(width: cardWidth, height: listHeight, radius: r.rs(18)),
            ),
          ),
          error: (_, __) => _NewsEmptyCard(l10n: l10n, onViewAll: onViewAll),
          data: (news) {
            if (news.isEmpty) return _NewsEmptyCard(l10n: l10n, onViewAll: onViewAll);
            return SizedBox(
              height: listHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: news.length,
                separatorBuilder: (_, __) => SizedBox(width: r.rs(12)),
                itemBuilder: (context, index) {
                  final item = news[index] as Map;
                  final isLocal = district != null &&
                      (item['district']?.toString().toLowerCase() ==
                          district!.toLowerCase());
                  return GestureDetector(
                    onTap: onViewAll,
                    child: Container(
                      width: cardWidth,
                      padding: EdgeInsets.all(r.rs(14)),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(r.rs(18)),
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isLocal)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: r.rs(8), vertical: r.rs(3)),
                                  decoration: BoxDecoration(
                                    color: AppColors.farmerTint,
                                    borderRadius: BorderRadius.circular(r.rs(8)),
                                  ),
                                  child: Text(l10n.localBadge,
                                      style: GoogleFonts.inter(
                                          fontSize: r.sp(10),
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.farmerAccent)),
                                )
                              else
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: r.rs(7), vertical: r.rs(3)),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceCard,
                                    borderRadius: BorderRadius.circular(r.rs(7)),
                                  ),
                                  child: Text(
                                    item['crop']?.toString() ??
                                        item['source']?.toString() ?? 'Market',
                                    style: GoogleFonts.inter(
                                        fontSize: r.sp(10),
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.muted),
                                  ),
                                ),
                              const Spacer(),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded,
                                      size: r.rs(11), color: AppColors.placeholder),
                                  SizedBox(width: r.rs(3)),
                                  Text(_timeAgo(item['publishedAt']?.toString()),
                                      style: GoogleFonts.inter(
                                          fontSize: r.sp(10), color: AppColors.placeholder)),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: r.rs(10)),
                          Text(
                            item['title']?.toString() ?? '',
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: r.sp(13.5),
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                                height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: r.rs(7)),
                          Expanded(
                            child: Text(
                              item['content']?.toString() ?? '',
                              style: GoogleFonts.inter(
                                  fontSize: r.sp(11.5), color: AppColors.muted, height: 1.4),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _NewsEmptyCard extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onViewAll;
  const _NewsEmptyCard({required this.l10n, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return GestureDetector(
      onTap: onViewAll,
      child: AgriCard(
        child: Row(
          children: [
            Container(
              width: r.rs(52), height: 52,
              decoration: BoxDecoration(
                  color: AppColors.farmerTint, borderRadius: BorderRadius.circular(r.rs(14))),
              child: Center(child: Text('📰', style: TextStyle(fontSize: r.sp(26)))),
            ),
            SizedBox(width: r.rs(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.noLocalNewsYet,
                      style: GoogleFonts.spaceGrotesk(fontSize: r.sp(15), fontWeight: FontWeight.w700)),
                  Text(l10n.tapBrowseNews,
                      style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: r.sp(14), color: AppColors.farmerAccent),
          ],
        ),
      ),
    );
  }
}

// ── Watch & Learn Section ─────────────────────────────────────────────────────
class _WatchLearnSection extends ConsumerWidget {
  final VoidCallback onViewAll;
  final void Function(Map<String, dynamic>) onVideoTap;

  const _WatchLearnSection({required this.onViewAll, required this.onVideoTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final videos = ref.watch(youtubeTrendingProvider);
    final ytCtx = ref.watch(youtubeLocaleProvider);
    final cardW = r.isTablet ? r.rs(240) : r.width * 0.52;
    final cardH = r.rs(190);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Watch & Learn',
          icon: Icons.play_circle_filled_rounded,
          trailing: _SeeAllChip(onTap: onViewAll, label: 'See All'),
        ),
        SizedBox(height: r.rs(4)),
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: r.rs(13), color: AppColors.farmerAccent),
            SizedBox(width: r.rs(3)),
            Expanded(
              child: Text(
                'Krishi TV • ${ytCtx.language.aiName} • ${ytCtx.district}',
                style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: r.rs(12)),
        videos.when(
          loading: () => SizedBox(
            height: cardH,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => SizedBox(width: r.rs(12)),
              itemBuilder: (_, __) =>
                  ShimmerBox(width: cardW, height: cardH, radius: r.rs(18)),
            ),
          ),
          error: (_, __) => _WatchLearnEmpty(onTap: onViewAll),
          data: (vids) {
            if (vids.isEmpty) return _WatchLearnEmpty(onTap: onViewAll);
            final preview = vids.take(6).toList();
            return SizedBox(
              height: cardH,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: preview.length,
                separatorBuilder: (_, __) => SizedBox(width: r.rs(12)),
                itemBuilder: (context, i) {
                  final vid = preview[i];
                  final videoId = vid['videoId']?.toString() ?? '';
                  final thumb = vid['thumbnail']?.toString().isNotEmpty == true
                      ? vid['thumbnail'].toString()
                      : 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
                  return GestureDetector(
                    onTap: () => onVideoTap(vid),
                    child: Container(
                      width: cardW,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(r.rs(18)),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(r.rs(18))),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: thumb,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      color: AppColors.farmerTint,
                                      child: Center(
                                          child: Text('🌾',
                                              style:
                                                  TextStyle(fontSize: r.sp(26)))),
                                    ),
                                  ),
                                  Center(
                                    child: Container(
                                      width: r.rs(36), height: r.rs(36),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white, size: r.sp(20)),
                                    ),
                                  ),
                                  Positioned(
                                    top: 6, right: 6,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: r.rs(5), vertical: r.rh(2)),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(r.rs(4)),
                                      ),
                                      child: Text('YT',
                                          style: GoogleFonts.inter(
                                              fontSize: r.sp(8),
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(r.rs(10)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      vid['title']?.toString() ?? 'Farming Video',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: r.sp(12),
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                        height: r.rh(1.3),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    vid['channel']?.toString() ?? '',
                                    style: GoogleFonts.inter(
                                        fontSize: r.sp(10), color: AppColors.muted),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _WatchLearnEmpty extends StatelessWidget {
  final VoidCallback onTap;
  const _WatchLearnEmpty({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return GestureDetector(
      onTap: onTap,
      child: AgriCard(
        child: Row(
          children: [
            Container(
              width: r.rs(52), height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(r.rs(14)),
              ),
              child: const Center(
                child: Icon(Icons.play_circle_rounded,
                    color: Color(0xFFCC0000), size: 28),
              ),
            ),
            SizedBox(width: r.rs(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Watch Farming Videos',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: r.sp(15), fontWeight: FontWeight.w700)),
                  Text('Tap to browse Krishi TV',
                      style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: r.sp(14), color: Color(0xFFCC0000)),
          ],
        ),
      ),
    );
  }
}
