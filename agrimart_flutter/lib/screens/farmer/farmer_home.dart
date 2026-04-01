import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/app_providers.dart';
import '../../data/providers/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_fallback.dart';
import '../../core/widgets/app_shimmer.dart';
import '../../core/widgets/floating_nav.dart';
import 'package:flutter/services.dart';
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
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _tab);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (_tab == index) return;
    HapticFeedback.lightImpact();
    setState(() => _tab = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
    );
  }

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
      extendBody: true, // Crucial for floating nav transparency
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Only via nav
        children: _tabs,
      ),
      bottomNavigationBar: FloatingDockNav(
        selectedIndex: _tab,
        onTabSelected: _onTabChanged,
        items: [
          FloatingNavItem(icon: '🏠', label: ref.tr('home')),
          FloatingNavItem(icon: '🛒', label: ref.tr('shop'), badge: cartCount > 0 ? cartCount : null),
          FloatingNavItem(icon: '🤖', label: ref.tr('ai')),
          FloatingNavItem(icon: '📈', label: ref.tr('mandi')),
          FloatingNavItem(icon: '👤', label: ref.tr('profile')),
        ],
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

// ── Custom Shimmers ────────────────────────────────────────
class _WeatherShimmer extends StatelessWidget {
  const _WeatherShimmer();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            AppShimmer(width: 50, height: 50, borderRadius: 25),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppShimmer(width: 120, height: 32, borderRadius: 8),
                  SizedBox(height: 8),
                  AppShimmer(width: 180, height: 16, borderRadius: 4),
                ],
              ),
            ),
            AppShimmer(width: 60, height: 36, borderRadius: 18),
          ],
        ),
      ),
    );
  }
}

class _OrderShimmer extends StatelessWidget {
  const _OrderShimmer();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const AppShimmer(width: 48, height: 48, borderRadius: 12),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer(width: 100, height: 20, borderRadius: 6),
                SizedBox(height: 8),
                AppShimmer(width: 60, height: 16, borderRadius: 4),
              ],
            ),
          ),
          const AppShimmer(width: 80, height: 26, borderRadius: 13),
        ],
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
    final lang = ref.watch(languageProvider);
    
    final name = auth.user?.name ?? (lang == 'English' ? 'Farmer' : 'शेतकरी');
    
    String greeting = 'Hello, $name 👋';
    if (lang == 'मराठी (Marathi)') greeting = 'नमस्कार, $name 🙏';
    if (lang == 'हिंदी (Hindi)') greeting = 'नमस्ते, $name 🙏';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(farmerDashboardProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: AppColors.primaryShadow,
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: auth.user?.profilePhoto != null
                            ? Image.network(auth.user!.profilePhoto!, fit: BoxFit.cover)
                            : const Center(child: Text('👨‍🌾', style: TextStyle(fontSize: 24))),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(greeting,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5)),
                          const SizedBox(height: 2),
                          Text(
                              DateTime.now().toLocal().toString().split(' ').first.replaceAll('-', ' • '),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.8))),
                        ],
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
                        onPressed: () => context.push('/notifications'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Data-dense Weather Widget
                _HomeWeatherWidget(dashboard: dashboard, ref: ref),

                const SizedBox(height: 16),

                // Data-Dense Financial KPI Strip
                dashboard.when(
                  loading: () => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: List.generate(3, (_) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 72,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppShimmer(width: 40, height: 12, borderRadius: 4),
                            const SizedBox(height: 8),
                            const AppShimmer(width: 60, height: 20, borderRadius: 4),
                          ],
                        ),
                      )
                    ))),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (data) {
                    final orders = (data['recentOrders'] as List? ?? []);
                    final totalSpend = orders.fold<double>(0, (s, o) =>
                        s + ((o['totalAmount'] as num? ?? 0).toDouble()));
                    final pending = orders.where((o) => (o['status'] as String? ?? '') == 'PENDING').length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(children: [
                        _StatChip('💰', 'Spent', '₹${_fmtNum(totalSpend)}', AppColors.success),
                        const SizedBox(width: 8),
                        _StatChip('📦', 'Pending', '$pending', AppColors.amber),
                        const SizedBox(width: 8),
                        _StatChip('🌾', 'Farm', '${data['farmSize'] ?? '–'} ha', AppColors.primary),
                      ]),
                    );
                  },
                ),
              
                const SizedBox(height: 24),

                // Premium Quick Actions Scroller
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(ref.tr('services_ai'), style: AppTextStyles.headingMD.copyWith(letterSpacing: -0.3)),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                    children: [
                      _QuickAction('🌿', ref.tr('shop'), const Color(0xFFE8F5E9), const Color(0xFF2E7D32), () => context.push('/farmer/shop')),
                      _QuickAction('🧪', ref.tr('soil_ai'), const Color(0xFFFFF3E0), const Color(0xFFE65100), () => context.push('/farmer/soil')),
                      _QuickAction('🔬', ref.tr('disease'), const Color(0xFFFFEBEE), const Color(0xFFC62828), () => context.push('/farmer/disease')),
                      _QuickAction('📤', ref.tr('mandi'), const Color(0xFFE3F2FD), const Color(0xFF1565C0), () => context.push('/farmer/mandi')),
                      _QuickAction('🌱', ref.tr('crops'), const Color(0xFFF1F8E9), const Color(0xFF33691E), () => context.push('/farmer/crop-advisor')),
                      _QuickAction('☁️', ref.tr('weather'), const Color(0xFFE1F5FE), const Color(0xFF0277BD), () => context.push('/farmer/weather')),
                      _QuickAction('💬', ref.tr('kisan_chat'), const Color(0xFFF3E5F5), const Color(0xFF6A1B9A), () => context.push('/farmer/kisan-ai')),
                      _QuickAction('🏛️', ref.tr('schemes'), const Color(0xFFFFFDE7), const Color(0xFFF57F17), () => context.push('/farmer/schemes')),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Recent Orders list
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Activity', style: AppTextStyles.headingMD.copyWith(letterSpacing: -0.3)),
                      GestureDetector(
                        onTap: () => context.push('/farmer/orders'),
                        child: Text('View All',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                dashboard.when(
                  loading: () => const Column(
                    children: [_OrderShimmer(), _OrderShimmer(), _OrderShimmer()],
                  ),
                  error: (e, _) => AppErrorState(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(farmerDashboardProvider)),
                  data: (data) {
                    final orders = data['recentOrders'] as List? ?? [];
                    if (orders.isEmpty) {
                      return const AppEmptyState(
                          icon: '📦',
                          title: 'No recent orders',
                          subtitle: 'Start exploring the marketplace!');
                    }
                    return Column(
                        children: orders
                            .take(3)
                            .map((o) => _OrderTile(order: o))
                            .toList());
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    ),
   );
  }
}

class _QuickAction extends StatefulWidget {
  final String emoji, label;
  final Color bgColor, textColor;
  final VoidCallback onTap;
  const _QuickAction(this.emoji, this.label, this.bgColor, this.textColor, this.onTap);

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.92),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: Container(
          width: 72,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: widget.bgColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: widget.bgColor.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(widget.emoji, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _fmtNum(double n) {
  if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return n.toStringAsFixed(0);
}

class _StatChip extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  const _StatChip(this.emoji, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
        ],
      ),
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
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('📦', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${(order['id'] as String).substring((order['id'] as String).length - 6).toUpperCase()}',
                  style: AppTextStyles.headingMD.copyWith(letterSpacing: -0.5, fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text('₹${order['totalAmount']}', style: AppTextStyles.priceSmall.copyWith(fontSize: 14, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.replaceAll('_', ' '),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: statusColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
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
      loading: () => const _WeatherShimmer(),
      error: (e, _) => AppErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(farmerDashboardProvider),
      ),
      data: (data) {
        final w = data['weather'];
        if (w == null) return const SizedBox.shrink();
        
        // Dynamic beautiful weather card styling depending on conditions
        final isSunny = (w['weather']?[0]?['main'] ?? '').toString().contains('Clear');
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: (isSunny ? const Color(0xFF0288D1) : const Color(0xFF455A64)).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isSunny 
                        ? [const Color(0xFF4FC3F7).withValues(alpha: 0.8), const Color(0xFF0288D1).withValues(alpha: 0.85)] 
                        : [const Color(0xFF78909C).withValues(alpha: 0.8), const Color(0xFF455A64).withValues(alpha: 0.85)],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(isSunny ? '☀️' : '🌥️', style: const TextStyle(fontSize: 32)),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${w['main']?['temp']?.toStringAsFixed(0) ?? '--'}°',
                                    style: const TextStyle(
                                        fontSize: 44,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1),
                                  ),
                                  Text(
                                    '${w['weather']?[0]?['main'] ?? ''}'.toUpperCase(),
                                    style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _DetailedWeatherPill(Icons.water_drop_rounded, '${w['main']?['humidity'] ?? '--'}%'),
                              const SizedBox(width: 8),
                              _DetailedWeatherPill(Icons.air_rounded, '${(w['wind']?['speed'] ?? 0).toStringAsFixed(1)}m/s'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Feels like',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${w['main']?['feels_like']?.toStringAsFixed(0) ?? '--'}°',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailedWeatherPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailedWeatherPill(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

extension StringCapitalize on String {
  String capitalize() => isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
}

class _WeatherPill extends StatelessWidget {
  final String text;
  const _WeatherPill(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}
