import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/app_providers.dart';

class SupplierDashboard extends ConsumerWidget {
  const SupplierDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              expandedHeight: 180,
              pinned: true,
              backgroundColor: AppColors.supplierAccent,
              leading: const SizedBox(),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: AppColors.supplierGradient),
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Welcome back', style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                                const SizedBox(height: 2),
                                Text(bizName, style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                              ],
                            ),
                          ),
                          if (!isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.warningTint,
                                borderRadius: BorderRadius.circular(20),
                              ),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Stat Grid ─────────────────────────────
                    dashboard.when(
                      loading: () => GridView.count(
                        crossAxisCount: 2, shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
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
                        crossAxisCount: 2, shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
                        children: [
                          StatCard(label: 'Orders This Week', value: '${d['ordersThisWeek'] ?? 0}', icon: Icons.shopping_bag_outlined, accent: AppColors.supplierAccent, tint: AppColors.supplierTint),
                          StatCard(label: 'Revenue (Month)', value: formatRupee((d['revenueThisMonth'] as num?) ?? 0), icon: Icons.currency_rupee_rounded, accent: AppColors.success, tint: AppColors.successTint),
                          StatCard(label: 'Active Listings', value: '${d['activeListings'] ?? 0}', icon: Icons.inventory_2_outlined, accent: AppColors.dealerAccent, tint: AppColors.dealerTint),
                          StatCard(label: 'Pending Orders', value: '${d['pendingOrders'] ?? 0}', icon: Icons.pending_outlined, accent: AppColors.warning, tint: AppColors.warningTint),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Quick Actions ─────────────────────────
                    Text('Quick Actions', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickBtn(
                            emoji: '➕', label: 'Add Product',
                            accent: AppColors.supplierAccent, tint: AppColors.supplierTint,
                            onTap: () => context.push('/supplier/add-product'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickBtn(
                            emoji: '📦', label: 'View Orders',
                            accent: AppColors.dealerAccent, tint: AppColors.dealerTint,
                            onTap: () => context.push('/supplier/orders'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Recent Orders ─────────────────────────
                    SectionHeader(title: 'Recent Orders', actionLabel: 'View all', onAction: () => context.push('/supplier/orders')),
                    dashboard.when(
                      loading: () => const ShimmerBox(height: 140, radius: 16),
                      error: (_, __) => const SizedBox(),
                      data: (d) {
                        final orders = (d['recentOrders'] as List?) ?? [];
                        if (orders.isEmpty) return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                          child: const EmptyState(emoji: '📦', title: 'No orders yet', subtitle: 'Orders will appear here'),
                        );
                        return Container(
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border), boxShadow: AppColors.softShadow),
                          child: Column(
                            children: List.generate(orders.take(2).length, (i) {
                              final o = orders[i] as Map;
                              return Column(children: [
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(children: [
                                    Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.supplierTint, borderRadius: BorderRadius.circular(10)), child: const Center(child: Text('🌱', style: TextStyle(fontSize: 20)))),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(o['farmerName'] ?? 'Farmer', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                                      Text(o['productName'] ?? 'Product', style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                                    ])),
                                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                      Text(formatRupee((o['amount'] as num?) ?? 0), style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 4),
                                      BadgeChip.status(o['status'] ?? 'Pending'),
                                    ]),
                                  ]),
                                ),
                                if (i < 1) const Divider(height: 1, color: AppColors.border),
                              ]);
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

class _SupplierStatsFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2, shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
    children: const [
      StatCard(label: 'Orders This Week', value: '--', icon: Icons.shopping_bag_outlined, accent: AppColors.supplierAccent, tint: AppColors.supplierTint),
      StatCard(label: 'Revenue (Month)', value: '₹--', icon: Icons.currency_rupee_rounded, accent: AppColors.success, tint: AppColors.successTint),
      StatCard(label: 'Active Listings', value: '--', icon: Icons.inventory_2_outlined, accent: AppColors.dealerAccent, tint: AppColors.dealerTint),
      StatCard(label: 'Pending Orders', value: '--', icon: Icons.pending_outlined, accent: AppColors.warning, tint: AppColors.warningTint),
    ],
  );
}

class _QuickBtn extends StatelessWidget {
  final String emoji, label;
  final Color accent, tint;
  final VoidCallback onTap;
  const _QuickBtn({required this.emoji, required this.label, required this.accent, required this.tint, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)), child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20)))),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ],
      ),
    ),
  );
}

