import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/app_providers.dart';
import '../../core/utils/responsive.dart';

class DealerDashboard extends ConsumerWidget {
  const DealerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final user      = ref.watch(authProvider).user;
    final dealer    = user?.dealer as Map? ?? {};
    final bizName   = dealer['businessName'] ?? user?.name ?? 'Dealer';
    final isVerified = user?.isVerified ?? false;
    final dashboard = ref.watch(dealerDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.dealerAccent,
        onRefresh: () async => ref.invalidate(dealerDashboardProvider),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: r.appBarExpandedHeight,
              pinned: true,
              backgroundColor: AppColors.dealerAccent,
              leading: const SizedBox(),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: AppColors.dealerGradient),
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Namaskar 🙏', style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                            const SizedBox(height: 2),
                            Text(bizName, style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      ),
                      if (!isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: AppColors.warningTint, borderRadius: BorderRadius.circular(20)),
                          child: Row(children: [
                            const Icon(Icons.schedule_rounded, color: AppColors.warning, size: 14),
                            const SizedBox(width: 4),
                            Text('Pending', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning)),
                          ]),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: AppColors.successTint, borderRadius: BorderRadius.circular(20)),
                          child: Row(children: [
                            const Icon(Icons.verified_rounded, color: AppColors.success, size: 14),
                            const SizedBox(width: 4),
                            Text('Verified', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)),
                          ]),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(onPressed: () => context.push('/notifications'), icon: const Icon(Icons.notifications_outlined, color: Colors.white)),
              ],
            ),

            SliverToBoxAdapter(
              child: ResponsiveLayout(
                applyPadding: false,
                child: Padding(
                padding: EdgeInsets.fromLTRB(r.horizontalPadding, r.rs(16), r.horizontalPadding, r.bottomNavInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stat grid
                    dashboard.when(
                      loading: () => GridView.count(
                        crossAxisCount: r.gridColumns(compact: 2, medium: 3, expanded: 4), shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
                        children: const [ShimmerBox(height: 100, radius: 16), ShimmerBox(height: 100, radius: 16), ShimmerBox(height: 100, radius: 16), ShimmerBox(height: 100, radius: 16)],
                      ),
                      error: (_, __) => _DealerStatsFallback(),
                      data: (d) => GridView.count(
                        crossAxisCount: r.gridColumns(compact: 2, medium: 3, expanded: 4), shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
                        children: [
                          StatCard(label: 'Active Deals',         value: '${d['activeDeals']     ?? d['activeRates']     ?? 0}', icon: Icons.handshake_outlined,   accent: AppColors.dealerAccent, tint: AppColors.dealerTint),
                          StatCard(label: 'Volume (Month, qtl)',  value: '${d['volumeThisMonth'] ?? d['totalBookings']   ?? 0}', icon: Icons.scale_outlined,        accent: AppColors.supplierAccent, tint: AppColors.supplierTint),
                          StatCard(label: 'Pending Pickups',      value: '${d['pendingPickups']  ?? d['pendingBookings'] ?? 0}', icon: Icons.local_shipping_outlined, accent: AppColors.warning,   tint: AppColors.warningTint),
                          StatCard(label: 'Avg Deal Size',        value: formatRupee((d['avgDealSize'] as num?) ?? 0),           icon: Icons.trending_up_rounded,     accent: AppColors.success,   tint: AppColors.successTint),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text('Quick Actions', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(16), fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _QuickBtn(emoji: '🌾', label: 'Browse Produce', accent: AppColors.dealerAccent, tint: AppColors.dealerTint, onTap: () => context.push('/dealer/produce-board'))),
                      const SizedBox(width: 12),
                      Expanded(child: _QuickBtn(emoji: '🤝', label: 'My Deals', accent: AppColors.farmerAccent, tint: AppColors.farmerTint, onTap: () => context.push('/dealer/my-deals'))),
                      const SizedBox(width: 12),
                      Expanded(child: _QuickBtn(emoji: '💹', label: 'My Rates', accent: AppColors.supplierAccent, tint: AppColors.supplierTint, onTap: () => context.push('/dealer/manage-rates'))),
                    ]),

                    const SizedBox(height: 24),

                    // Recent activity
                    SectionHeader(title: 'Recent Activity', actionLabel: 'View all', onAction: () => context.push('/dealer/my-deals')),
                    dashboard.when(
                      loading: () => const ShimmerBox(height: 120, radius: 16),
                      error: (_, __) => const SizedBox(),
                      data: (d) {
                        final bookings = (d['bookings'] as List?) ?? [];
                        if (bookings.isEmpty) return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                          child: const EmptyState(emoji: '🤝', title: 'No deals yet', subtitle: 'Browse produce to start dealing'),
                        );
                        return Container(
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border), boxShadow: AppColors.softShadow),
                          child: Column(children: List.generate(bookings.take(3).length, (i) {
                            final b = bookings[i] as Map;
                            return Column(children: [
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(children: [
                                  Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.dealerTint, borderRadius: BorderRadius.circular(10)), child: Center(child: Text('🌾', style: TextStyle(fontSize: r.sp(20))))),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(b['farmerName'] ?? b['crop'] ?? 'Deal', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                                    Text(b['crop'] ?? b['slotDate'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                                  ])),
                                  BadgeChip.status(b['status'] ?? 'Pending'),
                                ]),
                              ),
                              if (i < bookings.take(3).length - 1) const Divider(height: 1, color: AppColors.border),
                            ]);
                          })),
                        );
                      },
                    ),
                    SizedBox(height: r.bottomNavInset),
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

class _QuickBtn extends StatelessWidget {
  final String emoji, label; final Color accent, tint; final VoidCallback onTap;
  const _QuickBtn({required this.emoji, required this.label, required this.accent, required this.tint, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border), boxShadow: AppColors.softShadow),
      child: Column(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)), child: Center(child: Text(emoji, style: TextStyle(fontSize: r.sp(20))))),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
      ]),
    ),
    );
  }
}

class _DealerStatsFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return GridView.count(
    crossAxisCount: r.gridColumns(compact: 2, medium: 3, expanded: 4), shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
    mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
    children: const [
      StatCard(label: 'Active Deals', value: '--', icon: Icons.handshake_outlined, accent: AppColors.dealerAccent, tint: AppColors.dealerTint),
      StatCard(label: 'Volume (qtl)', value: '--', icon: Icons.scale_outlined, accent: AppColors.supplierAccent, tint: AppColors.supplierTint),
      StatCard(label: 'Pending Pickups', value: '--', icon: Icons.local_shipping_outlined, accent: AppColors.warning, tint: AppColors.warningTint),
      StatCard(label: 'Avg Deal Size', value: '₹--', icon: Icons.trending_up_rounded, accent: AppColors.success, tint: AppColors.successTint),
    ],
  );
  }
}

