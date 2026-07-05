import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agrimart/l10n/app_localizations.dart';
import '../../core/providers/locale_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final navItems = [
      RoleNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: l10n.home),
      RoleNavItem(icon: Icons.biotech_outlined, activeIcon: Icons.biotech_rounded, label: l10n.diagnose),
      RoleNavItem(icon: Icons.apps_rounded, activeIcon: Icons.apps_rounded, label: l10n.tools),
      RoleNavItem(icon: Icons.storefront_outlined, activeIcon: Icons.storefront_rounded, label: l10n.market),
      RoleNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: l10n.profile),
    ];

    final tabs = [
      const FarmerDashboard(),
      const CropDoctorScreen(),
      const FarmToolsScreen(embedded: true),
      const MarketScreen(),
      const FarmerProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        key: ValueKey('farmer-tabs-${locale.languageCode}'),
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: RoleBottomNav(
        currentIndex: _currentIndex,
        accent: AppColors.farmerAccent,
        onTap: (i) => setState(() => _currentIndex = i),
        items: navItems,
      ),
    );
  }
}
