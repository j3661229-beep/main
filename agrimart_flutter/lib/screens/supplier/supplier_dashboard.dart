import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/app_providers.dart';
import '../../core/utils/responsive.dart';

class SupplierDashboard extends ConsumerWidget {
  const SupplierDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final bizName = (user?.supplier as Map?)?['businessName'] ?? user?.name ?? 'Supplier';
    final isVerified = user?.isVerified ?? false;
    final dashboard = ref.watch(supplierDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.supplierAccent,
        onRefresh: () async => ref.invalidate(supplierDashboardProvider),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: r.appBarExpandedHeight,
              pinned: true,
              backgroundColor: AppColors.supplierAccent,
              leading: const SizedBox(),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: AppColors.supplierGradient),
                  padding: EdgeInsets.fromLTRB(r.rs(20), r.rh(60), r.rs(20), r.rh(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Welcome back', style: GoogleFonts.inter(fontSize: r.sp(12), color: Colors.white.withValues(alpha: 0.8))),
                                SizedBox(height: r.rh(2)),
                                Text(bizName, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(22), fontWeight: FontWeight.w700, color: Colors.white)),
                              ],
                            ),
                          ),
                          if (!isVerified)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: r.rs(10), vertical: r.rh(5)),
                              decoration: BoxDecoration(
                                color: AppColors.warningTint,
                                borderRadius: BorderRadius.circular(r.rs(20)),
                              ),
                              child: Row(children: [
                                Icon(Icons.schedule_rounded, color: AppColors.warning, size: r.sp(14)),
                                SizedBox(width: r.rs(4)),
                                Text('Pending', style: GoogleFonts.inter(fontSize: r.sp(11), fontWeight: FontWeight.w600, color: AppColors.warning)),
                              ]),
                            )
                          else
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: r.rs(10), vertical: r.rh(5)),
                              decoration: BoxDecoration(color: AppColors.successTint, borderRadius: BorderRadius.circular(r.rs(20))),
                              child: Row(children: [
                                Icon(Icons.verified_rounded, color: AppColors.success, size: r.sp(14)),
                                SizedBox(width: r.rs(4)),
                                Text('Verified', style: GoogleFonts.inter(fontSize: r.sp(11), fontWeight: FontWeight.w600, color: AppColors.success)),
                              ]),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () => context.push('/notifications'),
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                ),
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
                    // ── Stat Grid ─────────────────────────────
                    dashboard.when(
                      loading: () => GridView.count(
                        crossAxisCount: r.gridColumns(compact: 2, medium: 3, expanded: 4), shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
                        children: const [
                          ShimmerBox(height: 100, radius: 16),
                          ShimmerBox(height: 100, radius: 16),
                          ShimmerBox(height: 100, radius: 16),
                          ShimmerBox(height: 100, radius: 16),
                        ],
                      ),
                      error: (_, __) => _SupplierStatsFallback(),
                      data: (d) => GridView.count(
                        crossAxisCount: r.gridColumns(compact: 2, medium: 3, expanded: 4), shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
                        children: [
                          StatCard(label: 'Orders This Week', value: '${d['ordersThisWeek'] ?? 0}', icon: Icons.shopping_bag_outlined, accent: AppColors.supplierAccent, tint: AppColors.supplierTint),
                          StatCard(label: 'Revenue (Month)', value: formatRupee((d['revenueThisMonth'] as num?) ?? 0), icon: Icons.currency_rupee_rounded, accent: AppColors.success, tint: AppColors.successTint),
                          StatCard(label: 'Active Listings', value: '${d['activeListings'] ?? 0}', icon: Icons.inventory_2_outlined, accent: AppColors.dealerAccent, tint: AppColors.dealerTint),
                          StatCard(label: 'Pending Orders', value: '${d['pendingOrders'] ?? 0}', icon: Icons.pending_outlined, accent: AppColors.warning, tint: AppColors.warningTint),
                        ],
                      ),
                    ),

                    SizedBox(height: r.rh(24)),

                    // ── Quick Actions ─────────────────────────
                    Text('Quick Actions', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(16), fontWeight: FontWeight.w700, color: AppColors.ink)),
                    SizedBox(height: r.rh(12)),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickBtn(
                            emoji: '➕', label: 'Add Product',
                            accent: AppColors.supplierAccent, tint: AppColors.supplierTint,
                            onTap: () => context.push('/supplier/add-product'),
                          ),
                        ),
                        SizedBox(width: r.rs(12)),
                        Expanded(
                          child: _QuickBtn(
                            emoji: '📦', label: 'View Orders',
                            accent: AppColors.dealerAccent, tint: AppColors.dealerTint,
                            onTap: () => context.push('/supplier/orders'),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: r.rh(24)),

                    // ── Recent Orders ─────────────────────────
                    SectionHeader(title: 'Recent Orders', actionLabel: 'View all', onAction: () => context.push('/supplier/orders')),
                    dashboard.when(
                      loading: () => const ShimmerBox(height: 140, radius: 16),
                      error: (_, __) => const SizedBox(),
                      data: (d) {
                        final orders = (d['recentOrders'] as List?) ?? [];
                        if (orders.isEmpty) return Container(
                          padding: EdgeInsets.all(r.rs(24)),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(r.rs(16)), border: Border.all(color: AppColors.border)),
                          child: const EmptyState(emoji: '📦', title: 'No orders yet', subtitle: 'Orders will appear here'),
                        );
                        return Container(
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(r.rs(16)), border: Border.all(color: AppColors.border), boxShadow: AppColors.softShadow),
                          child: Column(
                            children: List.generate(orders.take(2).length, (i) {
                              final o = orders[i] as Map;
                              return Column(children: [
                                Padding(
                                  padding: EdgeInsets.all(r.rs(14)),
                                  child: Row(children: [
                                    Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.supplierTint, borderRadius: BorderRadius.circular(r.rs(10))), child: Center(child: Text('🌱', style: TextStyle(fontSize: r.sp(20))))),
                                    SizedBox(width: r.rs(12)),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(o['farmerName'] ?? 'Farmer', style: GoogleFonts.inter(fontSize: r.sp(13), fontWeight: FontWeight.w500)),
                                      Text(o['productName'] ?? 'Product', style: GoogleFonts.inter(fontSize: r.sp(12), color: AppColors.muted)),
                                    ])),
                                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                      Text(formatRupee((o['amount'] as num?) ?? 0), style: GoogleFonts.spaceGrotesk(fontSize: r.sp(13), fontWeight: FontWeight.w700)),
                                      SizedBox(height: r.rh(4)),
                                      BadgeChip.status(o['status'] ?? 'Pending'),
                                    ]),
                                  ]),
                                ),
                                if (i < 1) Divider(height: r.rh(1), color: AppColors.border),
                              ]);
                            }),
                          ),
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

class _SupplierStatsFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return GridView.count(
    crossAxisCount: r.gridColumns(compact: 2, medium: 3, expanded: 4), shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
    mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
    children: const [
      StatCard(label: 'Orders This Week', value: '--', icon: Icons.shopping_bag_outlined, accent: AppColors.supplierAccent, tint: AppColors.supplierTint),
      StatCard(label: 'Revenue (Month)', value: '₹--', icon: Icons.currency_rupee_rounded, accent: AppColors.success, tint: AppColors.successTint),
      StatCard(label: 'Active Listings', value: '--', icon: Icons.inventory_2_outlined, accent: AppColors.dealerAccent, tint: AppColors.dealerTint),
      StatCard(label: 'Pending Orders', value: '--', icon: Icons.pending_outlined, accent: AppColors.warning, tint: AppColors.warningTint),
    ],
  );
  }
}

class _QuickBtn extends StatelessWidget {
  final String emoji, label;
  final Color accent, tint;
  final VoidCallback onTap;
  const _QuickBtn({required this.emoji, required this.label, required this.accent, required this.tint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(vertical: r.rh(18)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r.rs(16)),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(r.rs(12))), child: Center(child: Text(emoji, style: TextStyle(fontSize: r.sp(20))))),
          SizedBox(height: r.rh(8)),
          Text(label, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(13), fontWeight: FontWeight.w600, color: AppColors.ink)),
        ],
      ),
    ),
    );
  }
}

