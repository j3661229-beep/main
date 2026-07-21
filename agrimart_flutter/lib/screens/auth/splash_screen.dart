import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/indian_languages.dart';
import '../../core/utils/farmer_prefetch.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
    _warmupAndNavigate();
  }

  Future<void> _waitForAuthInit() async {
    const maxWait = Duration(seconds: 4);
    final deadline = DateTime.now().add(maxWait);
    while (!ref.read(authProvider).isInitialized && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 40));
    }
  }

  Future<void> _warmupAndNavigate() async {
    final minSplash = Future.delayed(const Duration(milliseconds: 900));
    await _waitForAuthInit();

    final auth = ref.read(authProvider);
    if (auth.isAuthenticated && auth.farmSetupComplete) {
      prefetchFarmerHomeData(ref);
    } else if (!auth.isAuthenticated) {
      prefetchPublicData(ref);
    }

    await minSplash;
    if (mounted) _navigate();
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final hasChosenLang = prefs.getBool(IndianLanguages.chosenKey) ?? false;

    if (!hasChosenLang && mounted) {
      context.go('/auth/language');
      return;
    }

    final auth = ref.read(authProvider);
    if (auth.isAuthenticated && auth.user != null) {
      if (auth.user!.isFarmer) {
        if (mounted) {
          context.go(auth.farmSetupComplete ? '/farmer' : '/farmer/setup');
        }
      } else if (auth.user!.isDealer) {
        if (mounted) context.go('/dealer');
      } else {
        if (mounted) context.go('/supplier');
      }
    } else {
      if (mounted) context.go('/auth/login?role=FARMER');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: r.rs(100),
                    height: r.rh(100),
                    decoration: BoxDecoration(
                      color: AppColors.farmerTint,
                      borderRadius: BorderRadius.circular(r.rs(28)),
                      boxShadow: [BoxShadow(color: AppColors.farmerAccent.withValues(alpha: 0.4), blurRadius: r.rs(24), spreadRadius: r.rs(4))],
                    ),
                    child: Center(child: Text('🌾', style: TextStyle(fontSize: r.sp(52)))),
                  ),
                  SizedBox(height: r.rh(24)),
                  Text('AgriMart', style: TextStyle(fontSize: r.sp(36), fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                  SizedBox(height: r.rh(8)),
                  Text('शेतकऱ्यांचा विश्वासू साथीदार', style: TextStyle(fontSize: r.sp(15), color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
                  SizedBox(height: r.rh(48)),
                  SizedBox(width: r.rs(32), height: r.rh(32), child: CircularProgressIndicator(color: Colors.white.withValues(alpha: 0.4), strokeWidth: r.rs(2))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
