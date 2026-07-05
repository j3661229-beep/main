import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/agri_ui.dart';
import 'dealer_dashboard.dart';
import 'produce_board_screen.dart';
import 'dealer_profile_screen.dart';
import '../../core/utils/responsive.dart';

class DealerHome extends ConsumerStatefulWidget {
  const DealerHome({super.key});
  @override
  ConsumerState<DealerHome> createState() => _DealerHomeState();
}

class _DealerHomeState extends ConsumerState<DealerHome> {
  int _currentIndex = 0;

  static const _navItems = [
    RoleNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    RoleNavItem(icon: Icons.storefront_outlined, activeIcon: Icons.storefront_rounded, label: 'Board'),
    RoleNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  final _tabs = const [
    DealerDashboard(),
    ProduceBoardScreen(),
    DealerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: RoleBottomNav(
        currentIndex: _currentIndex,
        accent: AppColors.dealerAccent,
        onTap: (i) => setState(() => _currentIndex = i),
        items: _navItems,
      ),
    );
  }
}
