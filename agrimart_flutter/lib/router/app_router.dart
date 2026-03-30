import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers/auth_provider.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/auth/phone_screen.dart';
import '../screens/auth/otp_screen.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      
      if (state.matchedLocation == '/splash') return null;
      if (!authState.isAuthenticated && authState.user == null) {
        if (!state.matchedLocation.startsWith('/auth')) return '/auth/role';
        return null;
      }
      if (authState.isAuthenticated) {
        if (!authState.user!.isVerified && state.matchedLocation != '/auth/setup') {
          return '/auth/setup';
        }
        if (authState.user!.isVerified && (state.matchedLocation.startsWith('/auth') || state.matchedLocation == '/splash')) {
          return authState.user!.isFarmer ? '/farmer' : '/supplier';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),

      // Auth
      GoRoute(path: '/auth/role', builder: (_, __) => const RoleSelectionScreen()),
      GoRoute(path: '/auth/phone', builder: (ctx, state) {
        final role = state.uri.queryParameters['role'] ?? 'FARMER';
        return PhoneScreen(role: role);
      }),
      GoRoute(path: '/auth/otp', builder: (ctx, state) {
        final extra = state.extra as Map<String, String>? ?? {};
        return OTPScreen(phone: extra['phone'] ?? '', role: extra['role'] ?? 'FARMER');
      }),
      GoRoute(path: '/auth/onboarding', builder: (_, __) => const OnboardingScreen()), // The animated tour
      GoRoute(path: '/auth/setup', builder: (_, __) => const ProfileSetupScreen()), // The mandatory info form

      // Farmer
      GoRoute(path: '/farmer', builder: (_, __) => const FarmerHome()),
      GoRoute(path: '/farmer/shop', builder: (_, __) => const ShopScreen()),
      GoRoute(path: '/farmer/shop/product/:id', builder: (ctx, state) => ProductDetailScreen(productId: state.pathParameters['id']!)),
      GoRoute(path: '/farmer/cart', builder: (_, __) => const CartScreen()),
      GoRoute(path: '/farmer/checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(path: '/farmer/orders', builder: (_, __) => const OrdersScreen()),
      GoRoute(path: '/farmer/orders/:id/tracking', builder: (ctx, state) => OrderTrackingScreen(orderId: state.pathParameters['id']!)),
      GoRoute(path: '/farmer/soil', builder: (_, __) => const SoilAnalysisScreen()),
      GoRoute(path: '/farmer/disease', builder: (_, __) => const DiseaseDetectionScreen()),
      GoRoute(path: '/farmer/crop-advisor', builder: (_, __) => const CropAdvisorScreen()),
      GoRoute(path: '/farmer/weather', builder: (_, __) => const WeatherScreen()),
      GoRoute(path: '/farmer/mandi', builder: (_, __) => const MandiPricesScreen()),
      GoRoute(path: '/farmer/kisan-ai', builder: (_, __) => const KisanAiScreen()),
      GoRoute(path: '/farmer/schemes', builder: (_, __) => const SchemesScreen()),
      GoRoute(path: '/farmer/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),

      // Supplier
      GoRoute(path: '/supplier', builder: (_, __) => const SupplierHome()),
      GoRoute(path: '/supplier/orders', builder: (_, __) => const SupplierOrdersScreen()),
      GoRoute(path: '/supplier/add-product', builder: (_, __) => const AddProductScreen()),
      GoRoute(path: '/supplier/analytics', builder: (_, __) => const SupplierAnalyticsScreen()),
    ],
    errorBuilder: (ctx, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}', style: const TextStyle(fontSize: 16))),
    ),
  );

  ref.listen(authProvider, (previous, next) {
    if (previous?.isAuthenticated != next.isAuthenticated || previous?.user != next.user) {
      router.refresh();
    }
  });

  return router;
});
