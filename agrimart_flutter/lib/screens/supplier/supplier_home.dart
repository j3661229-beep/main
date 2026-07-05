import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/agri_ui.dart';
import 'supplier_dashboard.dart';
import 'supplier_orders_screen.dart';
import 'supplier_profile_screen.dart';
import '../../core/utils/responsive.dart';

class SupplierHome extends ConsumerStatefulWidget {
  const SupplierHome({super.key});
  @override
  ConsumerState<SupplierHome> createState() => _SupplierHomeState();
}

class _SupplierHomeState extends ConsumerState<SupplierHome> {
  int _currentIndex = 0;

  static const _navItems = [
    RoleNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    RoleNavItem(icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag_rounded, label: 'Orders'),
    RoleNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  final _tabs = const [
    SupplierDashboard(),
    SupplierOrdersScreen(),
    SupplierProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: RoleBottomNav(
        currentIndex: _currentIndex,
        accent: AppColors.supplierAccent,
        onTap: (i) => setState(() => _currentIndex = i),
        items: _navItems,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/supplier/add-product'),
              backgroundColor: AppColors.supplierAccent,
              elevation: 6,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text('Add Product', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, color: Colors.white)),
            )
          : null,
    );
  }
}
