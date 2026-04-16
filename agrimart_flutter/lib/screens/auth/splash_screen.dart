import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
    _warmupAndNavigate();
  }

  Future<void> _warmupAndNavigate() async {
    // Pre-warm the API cache while the splash is showing
    final auth = ref.read(authProvider);
    if (auth.isAuthenticated && auth.user != null) {
      try {
        // Kick off parallel prefetch requests to fill the cache
        await Future.wait([
          ref.read(farmerDashboardProvider.future).catchError((_) => <String, dynamic>{}),
          ref.read(weatherProvider.future).catchError((_) => <String, dynamic>{}),
          ref.read(cartProvider.notifier).load(),
        ]);
      } catch (_) {}
    }
    // Ensure at least 2 seconds of splash visibility
    await Future.delayed(const Duration(seconds: 2));
    _navigate();
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final hasChosenLang = (prefs.getString('selected_locale') ?? '').isNotEmpty;

    if (!hasChosenLang && mounted) {
      context.go('/auth/language');
      return;
    }

    final auth = ref.read(authProvider);
    if (auth.isAuthenticated && auth.user != null) {
      if (auth.user!.isFarmer) {
        if (mounted) context.go('/farmer');
      } else if (auth.user!.isDealer) {
        if (mounted) context.go('/dealer');
      } else {
        if (mounted) context.go('/supplier');
      }
    } else {
      if (mounted) context.go('/auth/role');
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }


  @override
  Widget build(BuildContext context) {
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
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.amberLight,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(color: AppColors.amber.withOpacity(0.4), blurRadius: 24, spreadRadius: 4)],
                    ),
                    child: const Center(child: Text('🌾', style: TextStyle(fontSize: 52))),
                  ),
                  const SizedBox(height: 24),
                  const Text('AgriMart', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  Text('शेतकऱ्यांचा विश्वासू साथीदार', style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 48),
                  SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: Colors.white.withOpacity(0.4), strokeWidth: 2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
