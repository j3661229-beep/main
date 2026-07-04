import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/constants/farm_tools.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/agri_ui.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/app_providers.dart';

class FarmerDashboard extends ConsumerWidget {
  const FarmerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 168,
              pinned: true,
              backgroundColor: AppColors.farmerAccent,
              leading: const SizedBox(),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(decoration: const BoxDecoration(gradient: AppColors.farmerGradient)),
                    Positioned(
                      right: -30,
                      top: 20,
                      child: Opacity(
                        opacity: 0.08,
                        child: Text('🌾', style: TextStyle(fontSize: 180)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
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
                                      'Namaste 🙏',
                                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      name,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_rounded, size: 13, color: Colors.white.withValues(alpha: 0.75)),
                                        const SizedBox(width: 4),
                                        Text(
                                          district,
                                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.75)),
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
                              const SizedBox(width: 8),
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInUp(
                      child: weather.when(
                        loading: () => const ShimmerBox(height: 130, radius: 22),
                        error: (_, __) => _WeatherError(),
                        data: (w) => WeatherHeroCard(
                          weather: w,
                          onTap: () => context.push('/farmer/advisory'),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    FadeInUp(
                      delay: const Duration(milliseconds: 80),
                      child: Text(
                        'Quick Actions',
                        style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeInUp(
                      delay: const Duration(milliseconds: 100),
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.35,
                        children: [
                          QuickActionTile(
                            emoji: '📰',
                            label: 'Mandi News',
                            sublabel: 'Local updates',
                            accent: AppColors.farmerAccent,
                            tint: AppColors.farmerTint,
                            onTap: () => context.push('/farmer/news'),
                          ),
                          QuickActionTile(
                            emoji: '🔬',
                            label: 'Scan Crop',
                            sublabel: 'AI diagnosis',
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
                            label: 'Buy Inputs',
                            sublabel: 'Seeds & more',
                            accent: AppColors.supplierAccent,
                            tint: AppColors.supplierTint,
                            onTap: () => context.push('/farmer/market'),
                          ),
                          QuickActionTile(
                            emoji: '💰',
                            label: 'Sell Produce',
                            sublabel: 'Dealer rates',
                            accent: AppColors.dealerAccent,
                            tint: AppColors.dealerTint,
                            onTap: () => context.push('/farmer/dealer-rates'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    FadeInUp(
                      delay: const Duration(milliseconds: 120),
                      child: FarmToolsBanner(onTap: () => context.push('/farmer/tools')),
                    ),
                    const SizedBox(height: 14),
                    FadeInUp(
                      delay: const Duration(milliseconds: 140),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Popular Tools',
                            style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
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
                                'See all',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.farmerAccent),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeInUp(
                      delay: const Duration(milliseconds: 160),
                      child: FarmToolsGrid(tools: featuredTools, crossAxisCount: 3, compact: true),
                    ),

                    const SizedBox(height: 28),

                    FadeInUp(
                      delay: const Duration(milliseconds: 180),
                      child: _MandiNewsSection(
                        district: user?.effectiveDistrict,
                        onViewAll: () => context.push('/farmer/news'),
                      ),
                    ),

                    const SizedBox(height: 28),

                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Orders',
                            style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/farmer/orders'),
                            child: Text(
                              'View all',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.farmerAccent),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    orders.when(
                      loading: () => const Column(
                        children: [
                          ShimmerBox(height: 76, radius: 18),
                          SizedBox(height: 10),
                          ShimmerBox(height: 76, radius: 18),
                        ],
                      ),
                      error: (_, __) => Text('Could not load orders', style: GoogleFonts.inter(color: AppColors.muted)),
                      data: (list) {
                        if (list.isEmpty) {
                          return _EmptyOrders(onShop: () => context.push('/farmer/market'));
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  '$badge',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WeatherError extends StatelessWidget {
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
                Text('Weather unavailable', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700)),
                Text('Pull down to refresh', style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  final VoidCallback onShop;
  const _EmptyOrders({required this.onShop});

  @override
  Widget build(BuildContext context) => AgriCard(
    child: Column(
      children: [
        const Text('🛍️', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 10),
        Text('No orders yet', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Browse the market for seeds, fertilizer & tools', style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        AppButton(label: 'Browse Market', onTap: onShop, height: 44, width: 180),
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
    final newsAsync = ref.watch(mandiNewsPreviewProvider);
    final locationLabel = district ?? 'Your area';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mandi News', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: AppColors.farmerAccent),
                    const SizedBox(width: 4),
                    Text('Near $locationLabel', style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ],
            ),
            GestureDetector(
              onTap: onViewAll,
              child: Text('View all', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.farmerAccent)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        newsAsync.when(
          loading: () => SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const ShimmerBox(width: 270, height: 160, radius: 18),
            ),
          ),
          error: (_, __) => _NewsEmptyCard(onViewAll: onViewAll),
          data: (news) {
            if (news.isEmpty) return _NewsEmptyCard(onViewAll: onViewAll);
            return SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: news.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = news[index] as Map;
                  final isLocal = district != null &&
                      (item['district']?.toString().toLowerCase() == district!.toLowerCase());
                  return GestureDetector(
                    onTap: onViewAll,
                    child: Container(
                      width: 270,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppColors.farmerTint, borderRadius: BorderRadius.circular(8)),
                                  child: Text('Local', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.farmerAccent)),
                                )
                              else
                                Text(
                                  item['crop']?.toString() ?? item['source']?.toString() ?? 'Market',
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.muted),
                                ),
                              const Spacer(),
                              Text(_timeAgo(item['publishedAt']?.toString()), style: GoogleFonts.inter(fontSize: 10, color: AppColors.muted)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item['title']?.toString() ?? '',
                            style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.25),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              item['content']?.toString() ?? '',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted, height: 1.35),
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
  final VoidCallback onViewAll;
  const _NewsEmptyCard({required this.onViewAll});

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
              child: const Center(child: Text('📰', style: TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No local news yet', style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700)),
                  Text('Tap to browse all market updates', style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
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
