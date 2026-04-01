import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers/auth_provider.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/auth/profile_setup_screen.dart';
import '../screens/farmer/farmer_home.dart';
import '../screens/farmer/shop_screen.dart';
import '../screens/farmer/product_detail_screen.dart';
import '../screens/farmer/cart_screen.dart';
import '../screens/farmer/checkout_screen.dart';
import '../screens/farmer/orders_screen.dart';
import '../screens/farmer/order_tracking_screen.dart';
import '../screens/farmer/soil_analysis_screen.dart';
import '../screens/farmer/disease_detection_screen.dart';
import '../screens/farmer/crop_advisor_screen.dart';
import '../screens/farmer/weather_screen.dart';
import '../screens/farmer/mandi_prices_screen.dart';
import '../screens/farmer/kisan_ai_screen.dart';
import '../screens/farmer/schemes_screen.dart';
import '../screens/farmer/profile_screen.dart';
import '../screens/supplier/supplier_home.dart';
import '../screens/supplier/supplier_orders_screen.dart';
import '../screens/supplier/add_product_screen.dart';
import '../screens/supplier/supplier_analytics_screen.dart';
import '../screens/shared/notifications_screen.dart';
import '../screens/dealer/dealer_home.dart';
import '../screens/dealer/manage_rates_screen.dart';
import '../screens/dealer/view_bookings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      
      // Global Redirect Logic
      if (state.matchedLocation == '/splash') return null;

      // Handle deep links from notifications (redirect logic)
      if (state.uri.path.startsWith('/n/')) {
        final parts = state.uri.path.split('/');
        if (parts.length >= 4) {
          final type = parts[2];
          final id = parts[3];
          if (type == 'PRODUCT') return '/farmer/shop/product/$id';
          if (type == 'ORDER') return '/farmer/orders/$id/tracking';
        }
      }

      if (!authState.isAuthenticated && authState.user == null) {
        if (!state.matchedLocation.startsWith('/auth')) return '/auth/role';
        return null;
      }
      if (authState.isAuthenticated) {
        if (!authState.user!.isVerified && state.matchedLocation != '/auth/setup') {
          return '/auth/setup';
        }
        if (authState.user!.isVerified && (state.matchedLocation.startsWith('/auth') || state.matchedLocation == '/splash')) {
          if (authState.user!.isFarmer) return '/farmer';
          if (authState.user!.isDealer) return '/dealer';
          return '/supplier';
        }
      }
      return null;
    },
    errorBuilder: (ctx, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}', style: const TextStyle(fontSize: 16))),
    ),
    routes: [
      _fadedRoute('/splash', const SplashScreen()),

      // Auth
      _fadedRoute('/auth/role', const RoleSelectionScreen()),
      GoRoute(path: '/auth/login', pageBuilder: (ctx, state) {
        final role = state.uri.queryParameters['role'] ?? 'FARMER';
        return _fadedPage(LoginScreen(role: role));
      }),
      _fadedRoute('/auth/onboarding', const OnboardingScreen()),
      _fadedRoute('/auth/setup', const ProfileSetupScreen()),

      // Farmer
      _fadedRoute('/farmer', const FarmerHome()),
      _fadedRoute('/farmer/shop', const ShopScreen()),
      GoRoute(path: '/farmer/shop/product/:id', pageBuilder: (ctx, state) => 
        _fadedPage(ProductDetailScreen(productId: state.pathParameters['id']!))),
      _fadedRoute('/farmer/cart', const CartScreen()),
      _fadedRoute('/farmer/checkout', const CheckoutScreen()),
      _fadedRoute('/farmer/orders', const OrdersScreen()),
      GoRoute(path: '/farmer/orders/:id/tracking', pageBuilder: (ctx, state) => 
        _fadedPage(OrderTrackingScreen(orderId: state.pathParameters['id']!))),
      _fadedRoute('/farmer/soil', const SoilAnalysisScreen()),
      _fadedRoute('/farmer/disease', const DiseaseDetectionScreen()),
      _fadedRoute('/farmer/crop-advisor', const CropAdvisorScreen()),
      _fadedRoute('/farmer/weather', const WeatherScreen()),
      _fadedRoute('/farmer/mandi', const MandiPricesScreen()),
      _fadedRoute('/farmer/kisan-ai', const KisanAiScreen()),
      _fadedRoute('/farmer/schemes', const SchemesScreen()),
      _fadedRoute('/farmer/profile', const ProfileScreen()),
      _fadedRoute('/notifications', const NotificationsScreen()),

      // Supplier
      _fadedRoute('/supplier', const SupplierHome()),
      _fadedRoute('/supplier/orders', const SupplierOrdersScreen()),
      _fadedRoute('/supplier/add-product', const AddProductScreen()),
      _fadedRoute('/supplier/analytics', const SupplierAnalyticsScreen()),

      // Dealer
      _fadedRoute('/dealer', const DealerHome()),
      _fadedRoute('/dealer/rates', const ManageRatesScreen()),
      _fadedRoute('/dealer/bookings', const DealerBookingsScreen()),
    ],
  );

  ref.listen(authProvider, (previous, next) {
    if (previous?.isAuthenticated != next.isAuthenticated || previous?.user != next.user) {
      router.refresh();
    }
  });

  return router;
});

// ── Helpers ─────────────────────────────────────────────────────────────────

GoRoute _fadedRoute(String path, Widget child) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => _fadedPage(child),
  );
}

CustomTransitionPage _fadedPage(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
    },
  );
}
