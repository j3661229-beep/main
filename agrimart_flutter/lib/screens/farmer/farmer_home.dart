import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'farmer_dashboard.dart';
import 'crop_doctor_screen.dart';
import 'market_screen.dart';
import 'farmer_profile_screen.dart';

class FarmerHome extends ConsumerStatefulWidget {
  final int initialTab;
  const FarmerHome({super.key, this.initialTab = 0});

  @override
  ConsumerState<FarmerHome> createState() => _FarmerHomeState();
}

class _FarmerHomeState extends ConsumerState<FarmerHome> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  final _tabs = const [
    FarmerDashboard(),
    CropDoctorScreen(),
    MarketScreen(),
    FarmerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded, outlinedIcon: Icons.home_outlined, label: 'Home',     index: 0, current: _currentIndex, accent: AppColors.farmerAccent, onTap: _onTap),
                _NavItem(icon: Icons.biotech_rounded, outlinedIcon: Icons.biotech_outlined, label: 'Diagnose', index: 1, current: _currentIndex, accent: AppColors.farmerAccent, onTap: _onTap),
                _NavItem(icon: Icons.storefront_rounded, outlinedIcon: Icons.storefront_outlined, label: 'Market',   index: 2, current: _currentIndex, accent: AppColors.farmerAccent, onTap: _onTap),
                _NavItem(icon: Icons.person_rounded, outlinedIcon: Icons.person_outlined, label: 'Profile',  index: 3, current: _currentIndex, accent: AppColors.farmerAccent, onTap: _onTap),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int i) => setState(() => _currentIndex = i);
}

class _NavItem extends StatelessWidget {
  final IconData icon, outlinedIcon;
  final String label;
  final int index, current;
  final Color accent;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.outlinedIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? accent.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? icon : outlinedIcon,
              color: isActive ? accent : AppColors.muted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? accent : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

