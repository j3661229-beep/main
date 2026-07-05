import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:agrimart/l10n/app_localizations.dart';
import '../../../core/constants/farm_tools.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/agri_ui.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/utils/farm_tool_l10n.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/app_providers.dart';

class FarmerDashboard extends ConsumerWidget {
  const FarmerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final name = user?.name ?? 'Kisan';
    final district = user?.effectiveDistrict ?? 'Nashik';
    final weather = ref.watch(weatherProvider);
    final orders = ref.watch(ordersProvider);
    final cartCount = ref.watch(cartItemCountProvider);
    final featuredTools = featuredFarmTools();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.farmerAccent,
        onRefresh: () async {
          ref.invalidate(weatherProvider);
          ref.invalidate(ordersProvider);
          ref.invalidate(farmerDashboardProvider);
          ref.invalidate(mandiNewsProvider);
          ref.invalidate(mandiTickerProvider);
          ref.invalidate(weatherAdvisoryProvider(district));
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: r.heroHeaderHeight,
              pinned: true,
              backgroundColor: AppColors.farmerAccent,
              leading: const SizedBox(),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(decoration: const BoxDecoration(gradient: AppColors.farmerGradient)),
                    Positioned(
                      right: -r.rs(30),
                      top: r.rs(20),
                      child: Opacity(
                        opacity: 0.08,
                        child: Text('🌾', style: TextStyle(fontSize: r.sp(180))),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(r.horizontalPadding, r.safePadding.top + r.rs(16), r.horizontalPadding, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${l10n.namaste} 🙏',
                                      style: GoogleFonts.inter(fontSize: r.sp(13), color: Colors.white.withValues(alpha: 0.8)),
                                    ),
                                    SizedBox(height: r.rs(4)),
                                    Text(
                                      name,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: r.sp(26),
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: r.rs(4)),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_rounded, size: r.rs(13), color: Colors.white.withValues(alpha: 0.75)),
                                        SizedBox(width: r.rs(4)),
                                        Text(
                                          district,
                                          style: GoogleFonts.inter(fontSize: r.sp(12), color: Colors.white.withValues(alpha: 0.75)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              _HeaderIconButton(
                                icon: Icons.shopping_cart_outlined,
                                badge: cartCount,
                                onTap: () => context.push('/farmer/cart'),
                              ),
                              SizedBox(width: r.rs(8)),
                              _HeaderIconButton(
                                icon: Icons.notifications_outlined,
                                onTap: () => context.push('/notifications'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: ResponsiveLayout(
                applyPadding: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(r.horizontalPadding, r.rs(16), r.horizontalPadding, r.bottomNavInset),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const OfflineBanner(),

                    FadeInUp(
                      child: weather.when(
                        loading: () => const ShimmerBox(height: 130, radius: 22),
                        error: (_, __) => _WeatherError(l10n: l10n),
                        data: (w) => WeatherHeroCard(
                          weather: w,
                          onTap: () => context.push('/farmer/advisory'),
                        ),
                      ),
                    ),

                    SizedBox(height: r.rs(14)),
                    FadeInUp(
                      delay: const Duration(milliseconds: 60),
                      child: _AdvisoryStrip(district: district),
                    ),

                    SizedBox(height: r.rs(14)),
                    FadeInUp(
                      delay: const Duration(milliseconds: 70),
                      child: _MandiTicker(district: district),
                    ),

                    SizedBox(height: r.rs(22)),

                    FadeInUp(
                      delay: const Duration(milliseconds: 80),
                      child: Text(
                        l10n.quickActions,
                        style: GoogleFonts.spaceGrotesk(fontSize: r.sp(18), fontWeight: FontWeight.w800, color: AppColors.ink),
                      ),
                    ),
                    SizedBox(height: r.rs(12)),
                    FadeInUp(
                      delay: const Duration(milliseconds: 100),
                      child: GridView.count(
                        crossAxisCount: r.quickActionColumns(),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: r.rs(12),
                        crossAxisSpacing: r.rs(12),
                        childAspectRatio: r.isTablet ? 1.5 : 1.35,
                        children: [
                          QuickActionTile(
                            emoji: '📰',
                            label: l10n.mandiNewsSection,
                            sublabel: l10n.localUpdates,
                            accent: AppColors.farmerAccent,
                            tint: AppColors.farmerTint,
                            onTap: () => context.push('/farmer/news'),
                          ),
                          QuickActionTile(
                            emoji: '🔬',
                            label: l10n.scanCrop,
                            sublabel: l10n.aiDiagnosis,
                            accent: AppColors.farmerAccent,
                            tint: AppColors.farmerTint,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2A4C25), Color(0xFF4A7A42)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () => context.push('/farmer/diagnose'),
                          ),
                          QuickActionTile(
                            emoji: '🛒',
                            label: l10n.buyInputs,
                            sublabel: l10n.seedsAndMore,
                            accent: AppColors.supplierAccent,
                            tint: AppColors.supplierTint,
                            onTap: () => context.push('/farmer/market'),
                          ),
                          QuickActionTile(
                            emoji: '💰',
                            label: l10n.sellProduceAction,
                            sublabel: l10n.listYourCrop,
                            accent: AppColors.dealerAccent,
                            tint: AppColors.dealerTint,
                            onTap: () => context.push('/farmer/dealer-rates'),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: r.rs(24)),

                    FadeInUp(
                      delay: const Duration(milliseconds: 120),
                      child: FarmToolsBanner(
                        onTap: () => context.push('/farmer/tools'),
                        badgeText: l10n.toolsCount(kFarmTools.length),
                        title: l10n.farmToolkit,
                        subtitle: l10n.farmToolkitCardSubtitle,
                      ),
                    ),
                    SizedBox(height: r.rs(14)),
                    FadeInUp(
                      delay: const Duration(milliseconds: 140),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.popularTools,
                            style: GoogleFonts.spaceGrotesk(fontSize: r.sp(18), fontWeight: FontWeight.w800, color: AppColors.ink),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/farmer/tools'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.farmerTint,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                l10n.seeAll,
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.farmerAccent),
                              ),
                            ),
                          ),
                        ],
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

                    FadeInUp(
                      delay: const Duration(milliseconds: 180),
                      child: _MandiNewsSection(
                        district: user?.effectiveDistrict,
                        onViewAll: () => context.push('/farmer/news'),
                      ),
                    ),

                    SizedBox(height: r.rs(28)),

                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.recentOrders,
                            style: GoogleFonts.spaceGrotesk(fontSize: r.sp(18), fontWeight: FontWeight.w800, color: AppColors.ink),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/farmer/orders'),
                            child: Text(
                              l10n.viewAll,
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.farmerAccent),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: r.rs(12)),

                    orders.when(
                      loading: () => const Column(
                        children: [
                          ShimmerBox(height: 76, radius: 18),
                          SizedBox(height: 10),
                          ShimmerBox(height: 76, radius: 18),
                        ],
                      ),
                      error: (_, __) => Text(l10n.couldNotLoadOrders, style: GoogleFonts.inter(color: AppColors.muted)),
                      data: (list) {
                        if (list.isEmpty) {
                          return _EmptyOrders(l10n: l10n, onShop: () => context.push('/farmer/market'));
                        }
                        final recent = list.take(2).toList();
                        return Column(
                          children: List.generate(recent.length, (i) {
                            final o = recent[i];
                            return Padding(
                              padding: EdgeInsets.only(bottom: i < recent.length - 1 ? 10 : 0),
                              child: AgriListTile(
                                emoji: '📦',
                                title: o['productName'] ?? o['product']?['name'] ?? 'Product',
                                subtitle: '${o['supplierName'] ?? 'Supplier'} • ${formatRupee((o['totalAmount'] as num?) ?? 0)}',
                                trailing: BadgeChip.status(o['status'] ?? 'Pending'),
                                onTap: () => context.push('/farmer/orders/${o['id']}/tracking'),
                              ),
                            );
                          }),
                        );
                      },
                    ),
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
            right: -2,
            top: -2,
            child: Container(
              width: r.rs(18),
              height: r.rs(18),
              decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  '$badge',
                  style: GoogleFonts.inter(fontSize: r.sp(10), fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WeatherError extends StatelessWidget {
  final AppLocalizations l10n;
  const _WeatherError({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return AgriCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.farmerTint, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.cloud_off_outlined, color: AppColors.muted),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.weatherUnavailable, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700)),
                Text(l10n.pullToRefresh, style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvisoryStrip extends ConsumerWidget {
  final String district;
  const _AdvisoryStrip({required this.district});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final l10n = AppLocalizations.of(context)!;
    final advisory = ref.watch(weatherAdvisoryProvider(district));

    return advisory.when(
      loading: () => const ShimmerBox(height: 72, radius: 16),
      error: (_, __) => const SizedBox.shrink(),
      data: (adv) {
        final list = adv['advisories'] as List?;
        final first = list != null && list.isNotEmpty ? list.first : null;
        final tip = first is Map ? first['tip']?.toString() : first?.toString();
        if (tip == null || tip.isEmpty) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => context.push('/farmer/advisory'),
          child: Container(
            padding: EdgeInsets.all(r.rs(14)),
            decoration: BoxDecoration(
              color: AppColors.warningTint,
              borderRadius: BorderRadius.circular(r.rs(16)),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Text('🌾', style: TextStyle(fontSize: r.sp(22))),
                SizedBox(width: r.rs(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.todaysAdvisory, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(13), fontWeight: FontWeight.w700, color: AppColors.warning)),
                      Text(tip, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.ink, height: 1.35)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.warning, size: r.rs(22)),
              ],
            ),
          ),
        );
      },
    );
  }
}

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
                Icon(Icons.trending_up_rounded, size: r.rs(16), color: AppColors.farmerAccent),
                SizedBox(width: r.rs(6)),
                Text(l10n.liveMandiRates, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(14), fontWeight: FontWeight.w700, color: AppColors.ink)),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/farmer/price-alerts'),
                  child: Text(l10n.tapForPriceAlerts, style: GoogleFonts.inter(fontSize: r.sp(11), fontWeight: FontWeight.w600, color: AppColors.farmerAccent)),
                ),
              ],
            ),
            SizedBox(height: r.rs(10)),
            SizedBox(
              height: r.rs(44),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: prices.length,
                separatorBuilder: (_, __) => SizedBox(width: r.rs(8)),
                itemBuilder: (_, i) {
                  final p = prices[i];
                  final crop = p['crop']?.toString() ?? p['commodity']?.toString() ?? 'Crop';
                  final price = p['price'] ?? p['modalPrice'] ?? p['avgPrice'];
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: r.rs(14), vertical: r.rs(10)),
                    decoration: BoxDecoration(
                      color: AppColors.farmerTint,
                      borderRadius: BorderRadius.circular(r.rs(12)),
                      border: Border.all(color: AppColors.farmerAccent.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Text(crop, style: GoogleFonts.inter(fontSize: r.sp(12), fontWeight: FontWeight.w600, color: AppColors.ink)),
                        SizedBox(width: r.rs(8)),
                        Text(
                          '${formatRupee((price as num?) ?? 0)}${l10n.perQuintalShort2}',
                          style: GoogleFonts.spaceGrotesk(fontSize: r.sp(12), fontWeight: FontWeight.w700, color: AppColors.farmerAccent),
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
  Widget build(BuildContext context) => AgriCard(
    child: Column(
      children: [
        const Text('🛍️', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 10),
        Text(l10n.noOrdersYet, style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(l10n.startShoppingInputs, style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        AppButton(label: l10n.browseMarket, onTap: onShop, height: 44, width: 180),
      ],
    ),
  );
}

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
    final listHeight = r.rs(160);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.mandiNewsSection, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(18), fontWeight: FontWeight.w800, color: AppColors.ink)),
                SizedBox(height: r.rs(2)),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: r.rs(14), color: AppColors.farmerAccent),
                    SizedBox(width: r.rs(4)),
                    Text(l10n.nearLocation(locationLabel), style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted)),
                  ],
                ),
              ],
            ),
            GestureDetector(
              onTap: onViewAll,
              child: Text(l10n.viewAll, style: GoogleFonts.inter(fontSize: r.sp(13), fontWeight: FontWeight.w600, color: AppColors.farmerAccent)),
            ),
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
              itemBuilder: (_, __) => ShimmerBox(width: cardWidth, height: listHeight, radius: r.rs(18)),
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
                      (item['district']?.toString().toLowerCase() == district!.toLowerCase());
                  return GestureDetector(
                    onTap: onViewAll,
                    child: Container(
                      width: cardWidth,
                      padding: EdgeInsets.all(r.rs(16)),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(r.rs(18)),
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isLocal)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: r.rs(8), vertical: r.rs(3)),
                                  decoration: BoxDecoration(color: AppColors.farmerTint, borderRadius: BorderRadius.circular(r.rs(8))),
                                  child: Text(l10n.localBadge, style: GoogleFonts.inter(fontSize: r.sp(10), fontWeight: FontWeight.w700, color: AppColors.farmerAccent)),
                                )
                              else
                                Text(
                                  item['crop']?.toString() ?? item['source']?.toString() ?? 'Market',
                                  style: GoogleFonts.inter(fontSize: r.sp(10), fontWeight: FontWeight.w600, color: AppColors.muted),
                                ),
                              const Spacer(),
                              Text(_timeAgo(item['publishedAt']?.toString()), style: GoogleFonts.inter(fontSize: r.sp(10), color: AppColors.muted)),
                            ],
                          ),
                          SizedBox(height: r.rs(10)),
                          Text(
                            item['title']?.toString() ?? '',
                            style: GoogleFonts.spaceGrotesk(fontSize: r.sp(14), fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.25),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: r.rs(8)),
                          Expanded(
                            child: Text(
                              item['content']?.toString() ?? '',
                              style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted, height: 1.35),
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
    return GestureDetector(
      onTap: onViewAll,
      child: AgriCard(
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: AppColors.farmerTint, borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text('📰', style: TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.noLocalNewsYet, style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(l10n.tapBrowseNews, style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.farmerAccent),
          ],
        ),
      ),
    );
  }
}
