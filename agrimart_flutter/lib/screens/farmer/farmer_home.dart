import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:agrimart/l10n/app_localizations.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/utils/farmer_prefetch.dart';
import '../../core/theme/app_colors.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/widgets/agri_ui.dart';
import 'farmer_dashboard.dart';
import 'crop_doctor_screen.dart';
import 'farm_tools_screen.dart';
import 'farmer_profile_screen.dart';
import 'kisan_ai_screen.dart';

class FarmerHome extends ConsumerStatefulWidget {
  final int initialTab;
  const FarmerHome({super.key, this.initialTab = 0});

  @override
  ConsumerState<FarmerHome> createState() => _FarmerHomeState();
}

class _FarmerHomeState extends ConsumerState<FarmerHome> {
  late int _currentIndex;
  final Set<int> _visitedTabs = {0};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _visitedTabs.add(widget.initialTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(farmSetupCompleteProvider)) {
        prefetchFarmerHomeData(ref);
      }
    });
  }

  void _onTabTap(int i) {
    final setupComplete = ref.read(authProvider).farmSetupComplete;
    if (!setupComplete && (i == 1 || i == 3)) {
      context.push('/farmer/setup');
      return;
    }
    setState(() {
      _visitedTabs.add(i);
      _currentIndex = i;
    });
  }

  Widget _tabAt(int i) {
    if (!_visitedTabs.contains(i)) return const SizedBox.shrink();
    final child = switch (i) {
      0 => const FarmerDashboard(),
      1 => const CropDoctorScreen(),
      2 => const FarmToolsScreen(embedded: true),
      3 => KisanAiScreen(embedded: true, isActive: _currentIndex == 3),
      4 => const FarmerProfileScreen(),
      _ => const SizedBox.shrink(),
    };
    return _KeepAliveTab(key: ValueKey('farmer-tab-$i'), child: child);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final navItems = [
      RoleNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: l10n.home),
      RoleNavItem(icon: Icons.biotech_outlined, activeIcon: Icons.biotech_rounded, label: l10n.diagnose),
      RoleNavItem(icon: Icons.apps_rounded, activeIcon: Icons.apps_rounded, label: l10n.tools),
      RoleNavItem(icon: Icons.smart_toy_outlined, activeIcon: Icons.smart_toy_rounded, label: 'Kisan AI'),
      RoleNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: l10n.profile),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        key: ValueKey('farmer-tabs-${locale.languageCode}'),
        index: _currentIndex,
        children: List.generate(5, _tabAt),
      ),
      bottomNavigationBar: RoleBottomNav(
        currentIndex: _currentIndex,
        accent: AppColors.farmerAccent,
        onTap: _onTabTap,
        items: navItems,
      ),
    );
  }
}

/// Keeps tab state after first visit without building all tabs upfront.
class _KeepAliveTab extends StatefulWidget {
  final Widget child;
  const _KeepAliveTab({super.key, required this.child});

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
