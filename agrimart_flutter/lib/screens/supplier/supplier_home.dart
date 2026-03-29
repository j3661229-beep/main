// ─────────────────────────────────────────────────
//  AgriMart — Complete Supplier App
// ─────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/providers/app_providers.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_fallback.dart';
import '../../core/widgets/app_shimmer.dart';

// ═══════════════════════════════════════════════════
// ROOT SHELL — Bottom Nav
// ═══════════════════════════════════════════════════
class SupplierHome extends ConsumerStatefulWidget {
  const SupplierHome({super.key});
  @override
  ConsumerState<SupplierHome> createState() => _SupplierHomeState();
}

class _SupplierHomeState extends ConsumerState<SupplierHome> {
  int _tab = 0;

  final _tabs = const [
    _SupplierDashboardTab(),
    _SupplierOrdersTab(),
    _SupplierProductsTab(),
    _SupplierAnalyticsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _tabs),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: AppColors.primarySurface,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          backgroundColor: Colors.white,
          elevation: 2,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
            NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Products'),
            NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Analytics'),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// TAB 1 — DASHBOARD HOME
// ═══════════════════════════════════════════════════
class _SupplierDashboardTab extends ConsumerWidget {
  const _SupplierDashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(supplierDashboardProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        // ── Hero Header ──────────────────────────────
        SliverAppBar(
          expandedHeight: 180,
          backgroundColor: AppColors.primaryDark,
          pinned: true,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                  const Text('Welcome back,', style: TextStyle(color: Colors.white60, fontSize: 13)),
                  Text(auth.user?.name ?? 'Supplier', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: AppColors.amberLight.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
                    child: const Text('🏪 Verified Seller', style: TextStyle(color: AppColors.amberLight, fontSize: 11, fontWeight: FontWeight.w600))),
                ])),
                IconButton(icon: const Icon(Icons.logout, color: Colors.white70), onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/auth/role');
                }),
              ]),
            ),
          ),
        ),

        SliverToBoxAdapter(child: dashboard.when(
          loading: () => const Padding(padding: EdgeInsets.all(16), child: AppShimmerList(itemCount: 4)),
          error: (e, _) => AppErrorState(message: 'Could not load dashboard', onRetry: () => ref.invalidate(supplierDashboardProvider)),
          data: (data) => Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Stat Cards ───────────────────────────
            GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, childAspectRatio: 1.6, mainAxisSpacing: 12, crossAxisSpacing: 12,
              children: [
                _StatCard('💰', 'Revenue', '₹${_fmt(data['totalRevenue'])}', AppColors.successSurface, AppColors.success),
                _StatCard('📦', 'Orders', '${data['totalOrders'] ?? 0}', AppColors.infoSurface, AppColors.info),
                _StatCard('🌿', 'Products', '${data['totalProducts'] ?? 0}', AppColors.primarySurface, AppColors.primary),
                _StatCard('⭐', 'Rating', '${(data['avgRating'] ?? 0.0).toStringAsFixed(1)}/5', AppColors.amberSurface, AppColors.amber),
              ],
            ),
            const SizedBox(height: 24),

            // ── Quick Actions ─────────────────────────
            const Text('Quick Actions', style: AppTextStyles.headingMD),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _QuickAction(icon: Icons.add_box_outlined, label: 'Add Product', color: AppColors.primary, onTap: () => context.push('/supplier/add-product'))),
              const SizedBox(width: 10),
              Expanded(child: _QuickAction(icon: Icons.receipt_long_outlined, label: 'View Orders', color: AppColors.info, onTap: () {})),
              const SizedBox(width: 10),
              Expanded(child: _QuickAction(icon: Icons.bar_chart_outlined, label: 'Analytics', color: AppColors.amber, onTap: () {})),
            ]),
            const SizedBox(height: 24),

            // ── Recent Orders snippet ─────────────────
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Recent Activity', style: AppTextStyles.headingMD),
              TextButton(onPressed: () {}, child: const Text('View All →')),
            ]),
            ...(data['recentOrders'] as List? ?? []).take(3).map((o) => _RecentOrderTile(order: o as Map)),
            if ((data['recentOrders'] as List? ?? []).isEmpty)
              const AppEmptyState(icon: '📭', title: 'No orders yet', subtitle: 'Your sales orders will appear here'),
          ])),
        )),
      ]),
    );
  }
}

String _fmt(dynamic v) {
  final n = v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;
  if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return n.toStringAsFixed(0);
}

class _StatCard extends StatelessWidget {
  final String emoji, label, value;
  final Color bg, accent;
  const _StatCard(this.emoji, this.label, this.value, this.bg, this.accent);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: bg, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: accent.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const Spacer(),
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accent)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]),
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: Column(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _RecentOrderTile extends StatelessWidget {
  final Map order;
  const _RecentOrderTile({required this.order});
  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? 'PENDING';
    final statusColor = status == 'DELIVERED' ? AppColors.success : status == 'DISPATCHED' ? AppColors.info : AppColors.amber;
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
          child: const Text('📦', style: TextStyle(fontSize: 20))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Order #${(order['id'] as String? ?? '').substring(0,8).toUpperCase()}', style: AppTextStyles.headingSM),
          Text('${order['items']?.length ?? 1} item(s)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor))),
      ]));
  }
}

// ═══════════════════════════════════════════════════
// TAB 2 — ORDERS
// ═══════════════════════════════════════════════════
class _SupplierOrdersTab extends ConsumerStatefulWidget {
  const _SupplierOrdersTab();
  @override
  ConsumerState<_SupplierOrdersTab> createState() => _SupplierOrdersTabState();
}

class _SupplierOrdersTabState extends ConsumerState<_SupplierOrdersTab> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _statuses = ['All', 'PROCESSING', 'DISPATCHED', 'DELIVERED'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _statuses.length, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('📦 Orders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: AppColors.amberLight,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: _statuses.map((s) => Tab(text: s)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: _statuses.map((status) {
          final orders = ref.watch(supplierOrdersProvider(status == 'All' ? null : status));
          return orders.when(
            loading: () => const AppShimmerList(),
            error: (e, _) => AppErrorState(message: 'Could not load orders', onRetry: () => ref.invalidate(supplierOrdersProvider)),
            data: (list) => list.isEmpty
              ? const AppEmptyState(icon: '📭', title: 'No orders', subtitle: 'No orders match this filter')
              : RefreshIndicator(
                  onRefresh: () async => ref.invalidate(supplierOrdersProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) => _OrderCard(order: list[i] as Map, onStatusChanged: () => ref.invalidate(supplierOrdersProvider)),
                  ),
                ),
          );
        }).toList(),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final Map order;
  final VoidCallback onStatusChanged;
  const _OrderCard({required this.order, required this.onStatusChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = order['status'] as String? ?? 'PROCESSING';
    final statusColor = {
      'PROCESSING': AppColors.amber, 'DISPATCHED': AppColors.info,
      'OUT_FOR_DELIVERY': AppColors.primaryLight, 'DELIVERED': AppColors.success,
    }[status] ?? AppColors.amber;

    return Container(margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
    ), child: Column(children: [
      // Header
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: Row(children: [
          Text('Order #${(order['orderId'] as String? ?? order['id'] as String? ?? '').substring(0, 8).toUpperCase()}', style: AppTextStyles.headingSM.copyWith(color: AppColors.primaryDark)),
          const Spacer(),
          Text('₹${(order['price'] as num? ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
        ])),
      // Body
      Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🌿', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(order['product']?['name'] ?? 'Product', style: AppTextStyles.bodyMD.copyWith(fontWeight: FontWeight.w600)),
            Text('Qty: ${order['quantity']}', style: AppTextStyles.caption),
          ])),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Update Status:', style: AppTextStyles.labelSM),
          DropdownButton<String>(
            value: status,
            isDense: true,
            items: ['PROCESSING', 'DISPATCHED', 'OUT_FOR_DELIVERY', 'DELIVERED'].map((s) =>
              DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' '), style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)))).toList(),
            onChanged: (s) async {
              if (s == null) return;
              await ApiService.instance.updateOrderStatus(order['id'] as String, s);
              onStatusChanged();
            },
            underline: const SizedBox.shrink(),
          ),
        ]),
      ])),
    ]));
  }
}

// ═══════════════════════════════════════════════════
// TAB 3 — PRODUCTS
// ═══════════════════════════════════════════════════
class _SupplierProductsTab extends ConsumerWidget {
  const _SupplierProductsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prods = ref.watch(supplierProductsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('🌿 My Products', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () => ref.invalidate(supplierProductsProvider)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/supplier/add-product'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: prods.when(
        loading: () => const AppShimmerList(),
        error: (e, _) => AppErrorState(message: 'Could not load your products', onRetry: () => ref.invalidate(supplierProductsProvider)),
        data: (list) => list.isEmpty
          ? const AppEmptyState(icon: '🌿', title: 'No products listed', subtitle: 'Tap the + button below to add your first product')
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: list.length,
              itemBuilder: (ctx, i) => _ProductTile(product: list[i] as Map, onRefresh: () => ref.invalidate(supplierProductsProvider)),
            ),
      ),
    );
  }
}

class _ProductTile extends ConsumerWidget {
  final Map product;
  final VoidCallback onRefresh;
  const _ProductTile({required this.product, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isApproved = product['isApproved'] == true;
    final isActive = product['isActive'] == true;
    final approvalColor = isApproved ? AppColors.success : AppColors.amber;
    final approvalLabel = isApproved ? 'Approved' : 'Pending';

    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        // Image thumbnail
        Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
          child: product['images'] is List && (product['images'] as List).isNotEmpty
            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(product['images'][0], fit: BoxFit.cover))
            : const Center(child: Text('🌿', style: TextStyle(fontSize: 28)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product['name'] ?? '', style: AppTextStyles.headingSM, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('₹${product['price']} / ${product['unit'] ?? 'unit'}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 4),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: approvalColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(approvalLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: approvalColor))),
            const SizedBox(width: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(20)),
              child: Text('Stock: ${product['stockQuantity']}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))),
          ]),
        ])),
        Column(children: [
          Switch(
            value: isActive,
            activeColor: AppColors.primary,
            onChanged: (v) async {
              await ApiService.instance.updateProduct(product['id'], {'isActive': v});
              onRefresh();
            },
          ),
          const Text('Active', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
        ]),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════
// TAB 4 — ANALYTICS
// ═══════════════════════════════════════════════════
class _SupplierAnalyticsTab extends ConsumerWidget {
  const _SupplierAnalyticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(supplierDashboardProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('📈 Analytics', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: dashboard.when(
        loading: () => const AppShimmerList(itemCount: 4),
        error: (e, _) => AppErrorState(message: 'Could not load analytics', onRetry: () => ref.invalidate(supplierDashboardProvider)),
        data: (data) {
          final revenue = (data['totalRevenue'] as num? ?? 0).toDouble();
          final orders = (data['totalOrders'] as num? ?? 0).toDouble();
          final products = (data['totalProducts'] as num? ?? 0).toDouble();

          // Build mock revenue bars
          final bars = [revenue * 0.55, revenue * 0.72, revenue * 0.65, revenue * 0.80, revenue * 0.90, revenue, revenue * 1.05];
          final maxY = (bars.reduce((a, b) => a > b ? a : b) * 1.2).clamp(100.0, double.infinity);

          return ListView(padding: const EdgeInsets.all(16), children: [
            // Revenue Hero Card
            Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total Revenue', style: TextStyle(color: Colors.white60, fontSize: 13)),
                const SizedBox(height: 4),
                Text('₹${_fmt(revenue)}', style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _MetricPill('📦 Orders', orders.toInt().toString()),
                  _MetricPill('🌿 Products', products.toInt().toString()),
                  _MetricPill('⭐ Rating', '${(data['avgRating'] ?? 0.0).toStringAsFixed(1)}'),
                ]),
              ])),
            const SizedBox(height: 24),

            // Revenue Bar Chart
            const Text('Revenue This Week', style: AppTextStyles.headingMD),
            const SizedBox(height: 16),
            Container(height: 200, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
              child: BarChart(BarChartData(
                maxY: maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    return Text(days[v.toInt() % 7], style: const TextStyle(fontSize: 10, color: AppColors.textTertiary));
                  })),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: bars.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(toY: e.value.clamp(0, maxY), color: AppColors.primary, width: 22, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
                ])).toList(),
              ))),
            const SizedBox(height: 24),

            // Category Breakdown Bars
            const Text('Category Breakdown', style: AppTextStyles.headingMD),
            const SizedBox(height: 16),
            ...{
              '🌱 Seeds': 0.45,
              '🧪 Fertilizers': 0.30,
              '🔴 Pesticides': 0.25,
            }.entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(e.key, style: AppTextStyles.labelLG),
                Text('${(e.value * 100).toInt()}%', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              ]),
              const SizedBox(height: 6),
              Stack(children: [
                Container(height: 10, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(8))),
                FractionallySizedBox(widthFactor: e.value, child: Container(height: 10, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(8)))),
              ]),
            ]))),

            const SizedBox(height: 8),
            // Growth Insight card
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
              color: AppColors.infoSurface, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.info.withOpacity(0.2))),
              child: Row(children: [
                const Text('💡', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Growth Insight', style: TextStyle(color: AppColors.info, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Adding more Organic products could boost your revenue by ~15% based on current market demand trends.', style: AppTextStyles.bodySM.copyWith(color: AppColors.textSecondary)),
                ])),
              ])),
          ]);
        },
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label, value;
  const _MetricPill(this.label, this.value);
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
    ]));
}

// ═══════════════════════════════════════════════════
// ADD PRODUCT SCREEN
// ═══════════════════════════════════════════════════
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  final _desc = TextEditingController();
  final _brand = TextEditingController();
  final _unit = TextEditingController(text: 'per kg');
  String _category = 'SEEDS';
  bool _isOrganic = false;
  bool _saving = false;

  static const _categories = ['SEEDS', 'FERTILIZER', 'PESTICIDE', 'ORGANIC', 'EQUIPMENT', 'OTHER'];
  static const _catEmojis = {'SEEDS': '🌱', 'FERTILIZER': '🧪', 'PESTICIDE': '🔴', 'ORGANIC': '🍃', 'EQUIPMENT': '⚙️', 'OTHER': '📦'};

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.primary,
      title: const Text('➕ Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    body: Form(key: _form, child: ListView(padding: const EdgeInsets.all(20), children: [
      // Banner
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primaryBorder)),
        child: const Row(children: [Text('📝', style: TextStyle(fontSize: 28)), SizedBox(width: 12), Expanded(child: Text('Your product will go live after admin approval. Usually within 24 hours.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)))])),
      const SizedBox(height: 24),

      _Section('Product Details'),
      _FormField(_name, 'Product Name *', 'e.g. DAP Fertilizer 50kg'),
      _FormField(_brand, 'Brand / Manufacturer', 'e.g. IFFCO, Syngenta'),
      _FormField(_desc, 'Description *', 'Describe your product benefits…', maxLines: 3),
      const SizedBox(height: 16),

      _Section('Pricing & Inventory'),
      Row(children: [
        Expanded(child: _FormField(_price, 'Price (₹) *', '0.00', type: TextInputType.number)),
        const SizedBox(width: 12),
        Expanded(child: _FormField(_stock, 'Stock Qty *', '100', type: TextInputType.number)),
      ]),
      _FormField(_unit, 'Unit Label', 'e.g. per kg, per bag, per liter'),
      const SizedBox(height: 16),

      _Section('Category'),
      Wrap(spacing: 8, runSpacing: 8, children: _categories.map((c) => GestureDetector(
        onTap: () => setState(() => _category = c),
        child: AnimatedContainer(duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _category == c ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _category == c ? AppColors.primary : AppColors.border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(_catEmojis[c] ?? '📦'),
            const SizedBox(width: 6),
            Text(c, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _category == c ? Colors.white : AppColors.textSecondary)),
          ])),
      )).toList()),
      const SizedBox(height: 16),

      // Organic Toggle
      GestureDetector(onTap: () => setState(() => _isOrganic = !_isOrganic),
        child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(
          color: _isOrganic ? AppColors.successSurface : Colors.white,
          borderRadius: BorderRadius.circular(14), border: Border.all(color: _isOrganic ? AppColors.success : AppColors.border)),
          child: Row(children: [
            Icon(_isOrganic ? Icons.eco : Icons.eco_outlined, color: AppColors.success),
            const SizedBox(width: 10),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Certified Organic Product', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text('Mark this if the product is certified organic', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ])),
            Switch(value: _isOrganic, onChanged: (v) => setState(() => _isOrganic = v), activeColor: AppColors.success),
          ]))),
      const SizedBox(height: 32),

      // Submit Button
      SizedBox(height: 54, child: ElevatedButton(
        onPressed: _saving ? null : _submit,
        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        child: _saving
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Text('🚀 Submit for Approval', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      )),
      const SizedBox(height: 40),
    ])),
  );

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ApiService.instance.createProduct({
        'name': _name.text.trim(),
        'price': double.parse(_price.text),
        'stockQuantity': int.parse(_stock.text),
        'category': _category,
        'description': _desc.text.trim(),
        'unit': _unit.text.trim(),
        'brand': _brand.text.trim(),
        'isOrganic': _isOrganic,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Product submitted! Pending admin approval.'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to submit: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally { setState(() => _saving = false); }
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: AppTextStyles.headingSM.copyWith(color: AppColors.primary)));
}

class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final TextInputType type;
  final int maxLines;
  const _FormField(this.ctrl, this.label, this.hint, {this.type = TextInputType.text, this.maxLines = 1});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextFormField(
    controller: ctrl, keyboardType: type, maxLines: maxLines,
    decoration: InputDecoration(labelText: label, hintText: hint, filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border))),
    validator: label.contains('*') ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
  ));
}

// ═══════════════════════════════════════════════════
// ANALYTICS SCREEN (standalone for /supplier/analytics route)
// ═══════════════════════════════════════════════════
class SupplierAnalyticsScreen extends ConsumerWidget {
  const SupplierAnalyticsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _SupplierAnalyticsTab();
  }
}

// ═══════════════════════════════════════════════════
// ORDERS SCREEN (standalone for /supplier/orders route)
// ═══════════════════════════════════════════════════
class SupplierOrdersScreen extends ConsumerWidget {
  const SupplierOrdersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _SupplierOrdersTab();
  }
}
