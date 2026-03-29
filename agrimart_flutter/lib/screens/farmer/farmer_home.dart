import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_fallback.dart';
import '../../core/widgets/app_shimmer.dart';
import 'shop_screen.dart';
import 'mandi_prices_screen.dart';
import 'profile_screen.dart';

class FarmerHome extends ConsumerStatefulWidget {
  const FarmerHome({super.key});
  @override
  ConsumerState<FarmerHome> createState() => _FarmerHomeState();
}

class _FarmerHomeState extends ConsumerState<FarmerHome> {
  int _tab = 0;

  final _tabs = const [
    _HomeTab(),
    ShopScreen(),
    AITabContent(),
    MandiPricesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      body: IndexedStack(index: _tab, children: _tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4))
        ]),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(children: [
              _NavItem(
                  icon: '🏠',
                  label: 'Home',
                  active: _tab == 0,
                  onTap: () => setState(() => _tab = 0)),
              _NavItem(
                  icon: '🛒',
                  label: 'Shop',
                  active: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                  badge: cartCount > 0 ? cartCount : null),
              _NavItem(
                  icon: '🤖',
                  label: 'AI',
                  active: _tab == 2,
                  onTap: () => setState(() => _tab = 2)),
              _NavItem(
                  icon: '📈',
                  label: 'Mandi',
                  active: _tab == 3,
                  onTap: () => setState(() => _tab = 3)),
              _NavItem(
                  icon: '👤',
                  label: 'Profile',
                  active: _tab == 4,
                  onTap: () => setState(() => _tab = 4)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String icon, label;
  final bool active;
  final VoidCallback onTap;
  final int? badge;
  const _NavItem(
      {required this.icon,
      required this.label,
      required this.active,
      required this.onTap,
      this.badge});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primarySurface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(alignment: Alignment.topCenter, children: [
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(icon, style: TextStyle(fontSize: active ? 24 : 22)),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color:
                          active ? AppColors.primary : AppColors.textTertiary)),
            ]),
            if (badge != null)
              Positioned(
                  right: 12,
                  top: 0,
                  child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                          color: AppColors.error, shape: BoxShape.circle),
                      child: Center(
                          child: Text('$badge',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700))))),
          ]),
        ),
      ),
    );
  }
}

// ── Home Tab ──────────────────────────────────────────────
class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final dashboard = ref.watch(farmerDashboardProvider);
    final name = auth.user?.name ?? 'शेतकरी';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        // Green header
        SliverAppBar(
          expandedHeight: 180,
          backgroundColor: AppColors.primary,
          pinned: true,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(children: [
                      Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                              color: AppColors.amberLight,
                              borderRadius: BorderRadius.circular(12)),
                          child: const Center(
                              child: Text('👨‍🌾',
                                  style: TextStyle(fontSize: 24)))),
                      const SizedBox(width: 12),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('नमस्ते, $name 🙏',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            Text(
                                DateTime.now()
                                    .toLocal()
                                    .toString()
                                    .split(' ')
                                    .first,
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Colors.white.withValues(alpha: 0.6))),
                          ]),
                      const Spacer(),
                      IconButton(
                          icon: const Icon(Icons.notifications_outlined,
                              color: Colors.white),
                          onPressed: () => context.push('/notifications')),
                    ]),
                  ]),
            ),
          ),
        ),

        SliverToBoxAdapter(
            child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Weather widget
            _HomeWeatherWidget(dashboard: dashboard, ref: ref),

            const SizedBox(height: 20),

            // Quick actions grid
            const Text('Quick Actions', style: AppTextStyles.headingLG),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              childAspectRatio: 0.9,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _QuickAction('🌿', 'Shop', () => context.push('/farmer/shop')),
                _QuickAction(
                    '🧪', 'Soil AI', () => context.push('/farmer/soil')),
                _QuickAction(
                    '🔬', 'Disease', () => context.push('/farmer/disease')),
                _QuickAction(
                    '📈', 'Mandi', () => context.push('/farmer/mandi')),
                _QuickAction(
                    '🌱', 'Crops', () => context.push('/farmer/crop-advisor')),
                _QuickAction(
                    '☁️', 'Weather', () => context.push('/farmer/weather')),
                _QuickAction(
                    '🤖', 'AI Chat', () => context.push('/farmer/kisan-ai')),
                _QuickAction(
                    '🏛️', 'Schemes', () => context.push('/farmer/schemes')),
              ],
            ),

            const SizedBox(height: 20),

            // Recent orders
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Recent Orders', style: AppTextStyles.headingLG),
              TextButton(
                  onPressed: () => context.push('/farmer/orders'),
                  child: const Text('View All →')),
            ]),
            dashboard.when(
              loading: () => const AppShimmerList(itemCount: 3),
              error: (e, _) => AppErrorState(
                  message: 'Could not load your orders',
                  onRetry: () => ref.invalidate(farmerDashboardProvider)),
              data: (data) {
                final orders = data['recentOrders'] as List? ?? [];
                if (orders.isEmpty) {
                  return const AppEmptyState(
                      icon: '📦',
                      title: 'No recent orders',
                      subtitle: 'Start exploring the shop!');
                }
                return Column(
                    children: orders
                        .take(3)
                        .map((o) => _OrderTile(order: o))
                        .toList());
              },
            ),
          ]),
        )),
      ]),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String emoji, label;
  final VoidCallback onTap;
  const _QuickAction(this.emoji, this.label, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

class _OrderTile extends StatelessWidget {
  final Map order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? 'PENDING';
    final statusColor = status == 'DELIVERED'
        ? AppColors.success
        : status == 'CANCELLED'
            ? AppColors.error
            : AppColors.amber;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10)),
            child: const Center(
                child: Text('📦', style: TextStyle(fontSize: 20)))),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              '#${(order['id'] as String).substring((order['id'] as String).length - 6).toUpperCase()}',
              style: AppTextStyles.headingSM),
          Text('₹${order['totalAmount']}', style: AppTextStyles.priceSmall),
        ])),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20)),
            child: Text(status.replaceAll('_', ' '),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor))),
      ]),
    );
  }
}

// ── AI Hub Tab ───────────────────────────────────────────
class AITabContent extends StatelessWidget {
  const AITabContent({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: const Text('🤖 AI Tools'), backgroundColor: AppColors.primary),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _AICard(
            '🧪',
            'Soil Analysis',
            'Analyze soil type & get fertilizer advice',
            () => context.push('/farmer/soil')),
        _AICard('🔬', 'Disease Detection', 'Identify crop diseases from photo',
            () => context.push('/farmer/disease')),
        _AICard('🌱', 'Crop Advisor', 'Get crop recommendations for your farm',
            () => context.push('/farmer/crop-advisor')),
        _AICard('💬', 'Kisan AI Chat', 'Chat in Marathi, Hindi or English',
            () => context.push('/farmer/kisan-ai')),
      ]),
    );
  }
}

class _AICard extends StatelessWidget {
  final String emoji, title, desc;
  final VoidCallback onTap;
  const _AICard(this.emoji, this.title, this.desc, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ]),
          child: Row(children: [
            Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(14)),
                child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 28)))),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title, style: AppTextStyles.headingMD),
                  const SizedBox(height: 2),
                  Text(desc, style: AppTextStyles.bodySM),
                ])),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textTertiary),
          ]),
        ),
      );
}

class _HomeWeatherWidget extends StatelessWidget {
  final AsyncValue<Map> dashboard;
  final WidgetRef ref;
  const _HomeWeatherWidget({required this.dashboard, required this.ref});

  @override
  Widget build(BuildContext context) {
    return dashboard.when(
      loading: () => const AppShimmerCard(),
      error: (e, _) => AppErrorState(
        message: 'Weather summary unavailable',
        onRetry: () => ref.invalidate(farmerDashboardProvider),
      ),
      data: (data) {
        final w = data['weather'];
        if (w == null) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF0288D1).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6))
              ]),
          child: Row(children: [
            const Text('☀️', style: TextStyle(fontSize: 38)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${w['main']?['temp']?.toStringAsFixed(0) ?? '--'}°C',
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    Text(
                        '${w['name'] ?? 'Your Location'} · ${w['weather']?[0]?['main'] ?? ''}',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ]),
            ),
            ElevatedButton(
              onPressed: () => context.push('/farmer/weather'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12)),
              child: const Text('Details', style: TextStyle(fontSize: 12)),
            ),
          ]),
        );
      },
    );
  }
}
