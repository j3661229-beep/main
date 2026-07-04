import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/agri_ui.dart';
import 'farmer_dashboard.dart';
import 'crop_doctor_screen.dart';
import 'market_screen.dart';
import 'farm_tools_screen.dart';
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

  static const _navItems = [
    RoleNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    RoleNavItem(icon: Icons.biotech_outlined, activeIcon: Icons.biotech_rounded, label: 'Diagnose'),
    RoleNavItem(icon: Icons.apps_rounded, activeIcon: Icons.apps_rounded, label: 'Tools'),
    RoleNavItem(icon: Icons.storefront_outlined, activeIcon: Icons.storefront_rounded, label: 'Market'),
    RoleNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  late final _tabs = const [
    FarmerDashboard(),
    CropDoctorScreen(),
    FarmToolsScreen(embedded: true),
    MarketScreen(),
    FarmerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: RoleBottomNav(
        currentIndex: _currentIndex,
        accent: AppColors.farmerAccent,
        onTap: (i) => setState(() => _currentIndex = i),
        items: _navItems,
      ),
    );
  }
}
