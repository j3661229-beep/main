import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/app_providers.dart';
import '../../data/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DealerHome extends ConsumerStatefulWidget {
  const DealerHome({super.key});
  @override
  ConsumerState<DealerHome> createState() => _DealerHomeState();
}

class _DealerHomeState extends ConsumerState<DealerHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardTab(user: user),
          const _RatesTab(),
          const _BookingsTab(),
          _ProfileTab(user: user),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', isActive: _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0)),
                _NavItem(icon: Icons.trending_up_rounded, label: 'Rates', isActive: _currentIndex == 1, onTap: () => setState(() => _currentIndex = 1)),
                _NavItem(icon: Icons.calendar_month_rounded, label: 'Bookings', isActive: _currentIndex == 2, onTap: () => setState(() => _currentIndex = 2)),
                _NavItem(icon: Icons.person_rounded, label: 'Profile', isActive: _currentIndex == 3, onTap: () => setState(() => _currentIndex = 3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DASHBOARD TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _DashboardTab extends ConsumerWidget {
  final dynamic user;
  const _DashboardTab({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dealerDashboardProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(dealerDashboardProvider),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.primary,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(child: Text('💰', style: TextStyle(fontSize: 24))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Welcome back,', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500)),
                                  Text(user?.name ?? 'Dealer', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => context.push('/notifications'),
                              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: dashboard.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.primary))),
                error: (e, _) => _ErrorCard(message: e.toString(), onRetry: () => ref.invalidate(dealerDashboardProvider)),
                data: (data) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Row
                    Row(children: [
                      Expanded(child: _StatCard(title: 'Active Rates', value: '${data['activeRates'] ?? 0}', icon: Icons.trending_up, color: const Color(0xFF2563EB))),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(title: 'Pending', value: '${data['pendingBookings'] ?? 0}', icon: Icons.hourglass_top, color: const Color(0xFFD97706))),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _StatCard(title: "Today's Slots", value: '${data['todaySlots'] ?? 0}', icon: Icons.calendar_today, color: const Color(0xFF059669))),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(title: 'Total Bookings', value: '${data['totalBookings'] ?? 0}', icon: Icons.assignment, color: const Color(0xFF7C3AED))),
                    ]),

                    const SizedBox(height: 32),
                    Text('Quick Actions', style: AppTextStyles.headingLG),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _QuickAction(icon: Icons.add_chart, label: 'Add Rate', color: AppColors.primary, onTap: () {})),
                      const SizedBox(width: 12),
                      Expanded(child: _QuickAction(icon: Icons.event_available, label: 'Slots', color: const Color(0xFF7C3AED), onTap: () => context.push('/dealer/slots'))),
                      const SizedBox(width: 12),
                      Expanded(child: _QuickAction(icon: Icons.schedule, label: 'Hours', color: const Color(0xFFD97706), onTap: () => context.push('/dealer/working-days'))),
                    ]),

                    const SizedBox(height: 32),
                    Text('Recent Bookings', style: AppTextStyles.headingLG),
                    const SizedBox(height: 16),
                    ..._buildRecentBookings(data['bookings'] as List? ?? []),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecentBookings(List bookings) {
    if (bookings.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(24),
            boxShadow: AppColors.softShadow, border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Column(children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle), child: const Text('📅', style: TextStyle(fontSize: 32))),
            const SizedBox(height: 16),
            Text('No Appointments Yet', style: AppTextStyles.headingMD),
            const SizedBox(height: 4),
            Text('Farmer bookings will appear here.', style: AppTextStyles.bodySM.copyWith(color: AppColors.textTertiary)),
          ]),
        ),
      ];
    }
    return bookings.take(3).map((b) => _BookingMiniCard(booking: b)).toList();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RATES TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _RatesTab extends ConsumerStatefulWidget {
  const _RatesTab();
  @override
  ConsumerState<_RatesTab> createState() => _RatesTabState();
}

class _RatesTabState extends ConsumerState<_RatesTab> {
  final _cropCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _addRate() async {
    if (_cropCtrl.text.isEmpty || _priceCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ApiService.instance.updateDealerRate({
        'cropName': _cropCtrl.text.trim(),
        'pricePerQuintal': double.parse(_priceCtrl.text.trim()),
      });
      _cropCtrl.clear();
      _priceCtrl.clear();
      ref.invalidate(dealerRatesProvider);
      ref.invalidate(dealerDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Rate broadcasted!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final rates = ref.watch(dealerRatesProvider);

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(dealerRatesProvider),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            Text('Manage Buying Rates', style: AppTextStyles.headingXL),
            const SizedBox(height: 4),
            Text('Set crop prices for farmers in your area.', style: AppTextStyles.bodySM.copyWith(color: AppColors.textSecondary)),

            const SizedBox(height: 28),

            // Add Rate Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(24),
                boxShadow: AppColors.softShadow, border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.add_chart, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Broadcast New Rate', style: AppTextStyles.headingMD),
                ]),
                const SizedBox(height: 20),
                Text('Crop Name', style: AppTextStyles.labelMD),
                const SizedBox(height: 6),
                TextField(controller: _cropCtrl, decoration: const InputDecoration(hintText: 'e.g. Soyabean, Cotton, Wheat')),
                const SizedBox(height: 16),
                Text('Price per Quintal (₹)', style: AppTextStyles.labelMD),
                const SizedBox(height: 6),
                TextField(controller: _priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'e.g. 4500')),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _addRate,
                    child: _saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('📢 Broadcast Rate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 32),
            Text('Your Active Rates', style: AppTextStyles.headingMD),
            const SizedBox(height: 12),

            rates.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())),
              error: (e, _) => _ErrorCard(message: e.toString(), onRetry: () => ref.invalidate(dealerRatesProvider)),
              data: (list) {
                if (list.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.softShadow),
                    child: Column(children: [
                      const Text('📊', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text('No rates yet', style: AppTextStyles.headingSM),
                      const SizedBox(height: 4),
                      Text('Add your first crop buying rate above.', style: AppTextStyles.bodySM),
                    ]),
                  );
                }
                return Column(children: list.map<Widget>((r) => _RateTile(rate: r)).toList());
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BOOKINGS TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _BookingsTab extends ConsumerStatefulWidget {
  const _BookingsTab();
  @override
  ConsumerState<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends ConsumerState<_BookingsTab> {
  String? _actionLoading; // 'accept-{id}' | 'reject-{id}'

  Future<void> _updateStatus(String id, String status) async {
    setState(() => _actionLoading = '$status-$id');
    try {
      await ApiService.instance.updateDealerBookingStatus(id, status);
      ref.invalidate(dealerBookingsProvider);
      ref.invalidate(dealerDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'ACCEPTED' ? '✅ Booking accepted!' : '❌ Booking rejected'), backgroundColor: status == 'ACCEPTED' ? AppColors.success : AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
    setState(() => _actionLoading = null);
  }

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(dealerBookingsProvider);

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(dealerBookingsProvider),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            Text('Farmer Appointments', style: AppTextStyles.headingXL),
            const SizedBox(height: 4),
            Text('Manage crop buying bookings from farmers.', style: AppTextStyles.bodySM.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 24),

            // Summary
            bookings.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (list) {
                final pending = list.where((b) => b['status'] == 'PENDING').length;
                final accepted = list.where((b) => b['status'] == 'ACCEPTED').length;
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppColors.primaryShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SummaryChip(label: 'Pending', value: '$pending', color: Colors.white),
                      Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
                      _SummaryChip(label: 'Accepted', value: '$accepted', color: Colors.white),
                      Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
                      _SummaryChip(label: 'Total', value: '${list.length}', color: Colors.white),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            bookings.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
              error: (e, _) => _ErrorCard(message: e.toString(), onRetry: () => ref.invalidate(dealerBookingsProvider)),
              data: (list) {
                if (list.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AppColors.softShadow),
                    child: Column(children: [
                      const Text('📦', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text('No bookings yet', style: AppTextStyles.headingMD),
                      Text('Farmers will book slots once you add rates.', style: AppTextStyles.bodySM),
                    ]),
                  );
                }
                return Column(children: list.map<Widget>((b) => _BookingCard(booking: b, actionLoading: _actionLoading, onAction: _updateStatus)).toList());
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROFILE TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _ProfileTab extends ConsumerWidget {
  final dynamic user;
  const _ProfileTab({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealer = user?.dealer as Map?;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),

          // Profile header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(28),
              boxShadow: AppColors.softShadow, border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Column(children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(child: Text(user?.initials ?? 'D', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900))),
              ),
              const SizedBox(height: 16),
              Text(user?.name ?? 'Dealer', style: AppTextStyles.headingXL),
              const SizedBox(height: 4),
              Text(user?.phone ?? '', style: AppTextStyles.bodySM.copyWith(fontFamily: 'monospace')),
              if (dealer?['businessName'] != null) ...[
                const SizedBox(height: 4),
                Text(dealer!['businessName'], style: AppTextStyles.labelMD.copyWith(color: AppColors.primary)),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: user?.isVerified == true ? AppColors.successSurface : AppColors.warningSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user?.isVerified == true ? '✅ Verified Dealer' : '⏳ Pending Verification',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: user?.isVerified == true ? AppColors.success : AppColors.warning),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // Business Info
          if (dealer != null) ...[
            _ProfileInfoCard(items: [
              _InfoRow(icon: Icons.store, label: 'Business', value: dealer['businessName'] ?? '—'),
              _InfoRow(icon: Icons.location_on, label: 'Location', value: '${dealer['district'] ?? ''}, ${dealer['state'] ?? ''}'),
              _InfoRow(icon: Icons.pin, label: 'Pincode', value: dealer['pincode'] ?? '—'),
            ]),
            const SizedBox(height: 16),
          ],

          // Actions
          _ProfileActionTile(icon: Icons.event_available, label: 'Generate Slots', subtitle: 'Create appointment time slots', onTap: () => context.push('/dealer/slots')),
          _ProfileActionTile(icon: Icons.schedule, label: 'Working Days & Hours', subtitle: 'Set your weekly schedule', onTap: () => context.push('/dealer/working-days')),
          _ProfileActionTile(icon: Icons.notifications_outlined, label: 'Notifications', subtitle: 'View alerts and updates', onTap: () => context.push('/notifications')),

          const SizedBox(height: 24),

          // Logout
          SizedBox(
            width: double.infinity, height: 54,
            child: OutlinedButton.icon(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// REUSABLE COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════════

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primarySurface : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: isActive ? AppColors.primary : AppColors.textTertiary, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: isActive ? AppColors.primary : AppColors.textTertiary)),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.softShadow, border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 14),
        Text(value, style: AppTextStyles.headingXL.copyWith(letterSpacing: -1, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(title, style: AppTextStyles.labelMD.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.softShadow, border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
      ),
    );
  }
}

class _RateTile extends StatelessWidget {
  final Map rate;
  const _RateTile({required this.rate});

  @override
  Widget build(BuildContext context) {
    final updated = DateTime.tryParse(rate['updatedAt'] ?? '');
    final timeAgo = updated != null ? _timeAgo(updated) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.softShadow, border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
          child: const Text('🌾', style: TextStyle(fontSize: 20)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(rate['cropName'] ?? '', style: AppTextStyles.headingSM),
          Text(timeAgo, style: AppTextStyles.caption),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₹${NumberFormat('#,##0').format(rate['pricePerQuintal'] ?? 0)}', style: AppTextStyles.priceSmall.copyWith(color: AppColors.primary, fontSize: 18)),
          Text('/quintal', style: AppTextStyles.caption),
        ]),
      ]),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _BookingMiniCard extends StatelessWidget {
  final Map booking;
  const _BookingMiniCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusColor = booking['status'] == 'ACCEPTED' ? AppColors.success : (booking['status'] == 'PENDING' ? AppColors.amber : Colors.grey);
    final farmerName = booking['farmer']?['user']?['name'] ?? 'Farmer';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.softShadow, border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        CircleAvatar(backgroundColor: AppColors.primarySurface, child: Text(farmerName[0], style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(farmerName, style: AppTextStyles.headingSM),
          Text('${booking['cropName']} • ${booking['approxQuintals']}Q', style: AppTextStyles.caption),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(booking['status'] ?? '', style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map booking;
  final String? actionLoading;
  final Function(String id, String status) onAction;
  const _BookingCard({required this.booking, this.actionLoading, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final statusColor = booking['status'] == 'ACCEPTED' ? AppColors.success : (booking['status'] == 'PENDING' ? AppColors.amber : Colors.grey);
    final farmerName = booking['farmer']?['user']?['name'] ?? 'Farmer';
    final farmerPhone = booking['farmer']?['user']?['phone'] ?? '';
    final slotDate = DateTime.tryParse(booking['slotDate'] ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.softShadow, border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
      ),
      child: Column(children: [
        Row(children: [
          CircleAvatar(backgroundColor: AppColors.primarySurface, child: Text(farmerName[0], style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(farmerName, style: AppTextStyles.headingMD),
            Text(farmerPhone, style: AppTextStyles.caption.copyWith(fontFamily: 'monospace')),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(booking['status'] ?? '', style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ]),
        const Divider(height: 28),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _DetailItem(label: 'Crop', value: booking['cropName'] ?? ''),
          _DetailItem(label: 'Qty', value: '${booking['approxQuintals']}Q'),
          _DetailItem(label: 'Rate', value: '₹${NumberFormat('#,##0').format(booking['pricePerQuintal'] ?? 0)}'),
          if (slotDate != null) _DetailItem(label: 'Date', value: DateFormat('d MMM').format(slotDate)),
        ]),
        if (booking['status'] == 'PENDING') ...[
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: actionLoading == 'CANCELLED-${booking['id']}' ? null : () => onAction(booking['id'], 'CANCELLED'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                child: actionLoading == 'CANCELLED-${booking['id']}'
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Reject'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: actionLoading == 'ACCEPTED-${booking['id']}' ? null : () => onAction(booking['id'], 'ACCEPTED'),
                child: actionLoading == 'ACCEPTED-${booking['id']}'
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Accept'),
              ),
            ),
          ]),
        ],
      ]),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryChip({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
    Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12)),
  ]);
}

class _DetailItem extends StatelessWidget {
  final String label, value;
  const _DetailItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: AppTextStyles.caption),
    const SizedBox(height: 2),
    Text(value, style: AppTextStyles.labelLG),
  ]);
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: AppColors.errorSurface, borderRadius: BorderRadius.circular(20)),
    child: Column(children: [
      const Text('⚠️', style: TextStyle(fontSize: 32)),
      const SizedBox(height: 8),
      Text(message, style: AppTextStyles.bodySM, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
    ]),
  );
}

class _ProfileInfoCard extends StatelessWidget {
  final List<_InfoRow> items;
  const _ProfileInfoCard({required this.items});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(22),
      boxShadow: AppColors.softShadow, border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
    ),
    child: Column(children: items.map((item) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(item.icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.label, style: AppTextStyles.caption),
          Text(item.value, style: AppTextStyles.headingSM),
        ])),
      ]),
    )).toList()),
  );
}

class _InfoRow {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final VoidCallback onTap;
  const _ProfileActionTile({required this.icon, required this.label, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.softShadow, border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: AppTextStyles.headingSM),
            Text(subtitle, style: AppTextStyles.caption),
          ])),
          const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ]),
      ),
    );
  }
}
