import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_colors.dart';
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
    final weather = ref.watch(weatherProvider);
    final orders  = ref.watch(ordersProvider);
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.farmerAccent,
        onRefresh: () async {
          ref.invalidate(weatherProvider);
          ref.invalidate(ordersProvider);
          ref.invalidate(farmerDashboardProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.farmerAccent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: AppColors.farmerGradient),
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Namaste 🙏', style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                              const SizedBox(height: 2),
                              Text(name, style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                            ],
                          ),
                          Row(
                            children: [
                              // Cart badge
                              Stack(
                                children: [
                                  IconButton(
                                    onPressed: () => context.push('/farmer/cart'),
                                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                                  ),
                                  if (cartCount > 0)
                                    Positioned(
                                      right: 6, top: 6,
                                      child: Container(
                                        width: 18, height: 18,
                                        decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                                        child: Center(child: Text('$cartCount', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white))),
                                      ),
                                    ),
                                ],
                              ),
                              IconButton(
                                onPressed: () => context.push('/notifications'),
                                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: const [],
              leading: const SizedBox(),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Weather Widget ──────────────────────────────
                    FadeInUp(
                      child: weather.when(
                        loading: () => const ShimmerBox(height: 110, radius: 16),
                        error: (_, __) => _WeatherError(),
                        data: (w) => _WeatherCard(weather: w),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Quick Actions ────────────────────────────────
                    FadeInUp(
                      delay: const Duration(milliseconds: 100),
                      child: Text('Quick Actions', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    ),
                    const SizedBox(height: 12),
                    FadeInUp(
                      delay: const Duration(milliseconds: 150),
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          _QuickAction(emoji: '📰', label: 'Mandi News', sublabel: 'Local updates', color: AppColors.farmerAccent, tint: AppColors.farmerTint, onTap: () => context.push('/farmer/news')),
                          _QuickAction(emoji: '🔬', label: 'Scan a Crop', sublabel: 'AI Diagnosis', color: AppColors.farmerAccent, tint: AppColors.farmerTint, onTap: () => context.push('/farmer/diagnose')),
                          _QuickAction(emoji: '🛒', label: 'Buy Inputs', sublabel: 'Seeds & More', color: AppColors.supplierAccent, tint: AppColors.supplierTint, onTap: () => context.push('/farmer/market')),
                          _QuickAction(emoji: '💰', label: 'Sell Produce', sublabel: 'List your crop', color: AppColors.dealerAccent, tint: AppColors.dealerTint, onTap: () => context.push('/farmer/market?tab=sell')),
                        ],
                      ),

                    ),

                    const SizedBox(height: 24),

                    // ── Recent Orders ────────────────────────────────
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Orders', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          GestureDetector(
                            onTap: () => context.push('/farmer/orders'),
                            child: Text('View all', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.farmerAccent)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    orders.when(
                      loading: () => Column(children: [
                        const ShimmerBox(height: 72, radius: 12),
                        const SizedBox(height: 8),
                        const ShimmerBox(height: 72, radius: 12),
                      ]),
                      error: (_, __) => Text('Could not load orders', style: GoogleFonts.inter(color: AppColors.muted)),
                      data: (list) {
                        if (list.isEmpty) {
                          return _EmptyOrders(onShop: () => context.push('/farmer/market'));
                        }
                        final recent = list.take(2).toList();
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                            boxShadow: AppColors.softShadow,
                          ),
                          child: Column(
                            children: List.generate(recent.length, (i) {
                              final o = recent[i];
                              return Column(
                                children: [
                                  GestureDetector(
                                    onTap: () => context.push('/farmer/orders/${o['id']}/tracking'),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44, height: 44,
                                            decoration: BoxDecoration(color: AppColors.farmerTint, borderRadius: BorderRadius.circular(12)),
                                            child: const Center(child: Text('📦', style: TextStyle(fontSize: 22))),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(o['productName'] ?? o['product']?['name'] ?? 'Product', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
                                                Text(o['supplierName'] ?? 'Supplier', style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(formatRupee((o['totalAmount'] as num?) ?? 0), style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                                              const SizedBox(height: 4),
                                              BadgeChip.status(o['status'] ?? 'Pending'),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (i < recent.length - 1) const Divider(height: 1, color: AppColors.border),
                                ],
                              );
                            }),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 100),
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

class _WeatherCard extends StatelessWidget {
  final Map weather;
  const _WeatherCard({required this.weather});

  @override
  Widget build(BuildContext context) {
    final temp = weather['temperature'] ?? weather['temp'] ?? '--';
    final desc = weather['description'] ?? weather['condition'] ?? 'Clear';
    final humidity = weather['humidity'] ?? '--';
    final wind = weather['windSpeed'] ?? weather['wind_speed'] ?? '--';
    final location = weather['location'] ?? weather['city'] ?? 'Your Location';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(location, style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                const SizedBox(height: 4),
                Text('$temp°C', style: GoogleFonts.spaceGrotesk(fontSize: 40, fontWeight: FontWeight.w700, color: Colors.white)),
                Text(desc, style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('🌤️', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.water_drop_outlined, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text('$humidity%', style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                const SizedBox(width: 12),
                const Icon(Icons.air, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text('${wind}km/h', style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherError extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.muted),
          const SizedBox(width: 12),
          Text('Weather unavailable', style: GoogleFonts.inter(color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String emoji, label, sublabel;
  final Color color, tint;
  final VoidCallback onTap;
  const _QuickAction({required this.emoji, required this.label, required this.sublabel, required this.color, required this.tint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
            Text(sublabel, style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  final VoidCallback onShop;
  const _EmptyOrders({required this.onShop});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
    child: Column(
      children: [
        const Text('🛍️', style: TextStyle(fontSize: 36)),
        const SizedBox(height: 8),
        Text('No orders yet', style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
        const SizedBox(height: 4),
        Text('Start shopping for farm inputs', style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 12),
        AppButton(label: 'Browse Market', onTap: onShop, height: 42, width: 150),
      ],
    ),
  );
}

