import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class DealerHome extends ConsumerWidget {
  const DealerHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, user?.name ?? 'Dealer'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCards(),
                  const SizedBox(height: 32),
                  Text('Quick Actions', style: AppTextStyles.headingLG),
                  const SizedBox(height: 16),
                  _buildActionGrid(context),
                  const SizedBox(height: 32),
                  Text('Recent Appointments', style: AppTextStyles.headingLG),
                  const SizedBox(height: 16),
                  _buildRecentBookings(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String name) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('Welcome, $name', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        background: Container(decoration: const BoxDecoration(gradient: AppColors.heroGradient)),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () => ProviderScope.containerOf(context).read(authProvider.notifier).logout(),
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(child: _StatCard(title: 'Active Rates', value: '12', icon: Icons.trending_up, color: const Color(0xFF2563EB))),
        const SizedBox(width: 16),
        Expanded(child: _StatCard(title: 'Slots Today', value: '08', icon: Icons.calendar_today, color: const Color(0xFFD97706))),
      ],
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _ActionCard(
          title: 'Update Rates',
          subtitle: 'Set crop prices',
          icon: Icons.edit_note,
          color: const Color(0xFF059669),
          onTap: () => context.push('/dealer/rates'),
        ),
        _ActionCard(
          title: 'View Bookings',
          subtitle: 'Manage slots',
          icon: Icons.assignment,
          color: const Color(0xFF7C3AED),
          onTap: () => context.push('/dealer/bookings'),
        ),
      ],
    );
  }

  Widget _buildRecentBookings() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.softShadow,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
            child: const Text('📅', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 16),
          Text('No Appointments Yet', style: AppTextStyles.headingMD),
          const SizedBox(height: 4),
          Text('Farmer bookings will appear here.', style: AppTextStyles.bodySM.copyWith(color: AppColors.textTertiary)),
        ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: AppTextStyles.headingXL.copyWith(letterSpacing: -1, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(title, style: AppTextStyles.labelMD.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.softShadow,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(title, style: AppTextStyles.headingSM.copyWith(letterSpacing: -0.2)),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
