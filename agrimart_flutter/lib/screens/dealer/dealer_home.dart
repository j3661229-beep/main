import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'dealer_dashboard.dart';
import 'produce_board_screen.dart';
import 'dealer_profile_screen.dart';

class DealerHome extends ConsumerStatefulWidget {
  const DealerHome({super.key});
  @override
  ConsumerState<DealerHome> createState() => _DealerHomeState();
}

class _DealerHomeState extends ConsumerState<DealerHome> {
  int _currentIndex = 0;

  final _tabs = const [
    DealerDashboard(),
    ProduceBoardScreen(),
    DealerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded,     outlinedIcon: Icons.home_outlined,     label: 'Home',  index: 0, current: _currentIndex, accent: AppColors.dealerAccent, onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.storefront_rounded, outlinedIcon: Icons.storefront_outlined, label: 'Board', index: 1, current: _currentIndex, accent: AppColors.dealerAccent, onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.person_rounded,   outlinedIcon: Icons.person_outlined,   label: 'Profile', index: 2, current: _currentIndex, accent: AppColors.dealerAccent, onTap: (i) => setState(() => _currentIndex = i)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, outlinedIcon; final String label; final int index, current; final Color accent; final void Function(int) onTap;
  const _NavItem({required this.icon, required this.outlinedIcon, required this.label, required this.index, required this.current, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(color: isActive ? accent.withValues(alpha: 0.1) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? icon : outlinedIcon, color: isActive ? accent : AppColors.muted, size: 24),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: isActive ? accent : AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

