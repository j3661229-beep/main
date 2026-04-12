import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers/auth_provider.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/auth/profile_setup_screen.dart';
import '../screens/auth/language_selection_screen.dart';
import '../screens/auth/doc_upload_screen.dart';
import '../screens/auth/pending_approval_screen.dart';
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
import '../screens/farmer/trade_booking_screen.dart';
import '../screens/supplier/supplier_home.dart';
import '../screens/supplier/supplier_orders_screen.dart';
import '../screens/supplier/add_product_screen.dart';
import '../screens/supplier/supplier_analytics_screen.dart';
import '../screens/shared/notifications_screen.dart';
import '../screens/dealer/dealer_home.dart';
import '../screens/dealer/manage_rates_screen.dart';
import '../screens/dealer/view_bookings_screen.dart';
import '../screens/dealer/dealer_slots_screen.dart';
import '../screens/dealer/dealer_working_days_screen.dart';


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
        final user = authState.user!;

        // Supplier/Dealer without uploaded doc → doc upload
        final supplier = user.supplier as Map?;
        final dealer = user.dealer as Map?;
        final supplierDocStatus = supplier?['docStatus'] as String?;
        final dealerDocStatus = dealer?['docStatus'] as String?;
        final hasUploadedDoc = (supplier?['govtDocUrl'] != null) || (dealer?['govtDocUrl'] != null);
        final isPending = (supplierDocStatus == 'PENDING' && hasUploadedDoc) ||
                         (dealerDocStatus == 'PENDING' && hasUploadedDoc);
        final needsDocUpload = !user.isFarmer && !hasUploadedDoc;


        final hasProfileBasics = (supplier?['businessName'] != null && supplier?['businessName'] != 'My Agency') ||
                                (dealer?['businessName'] != null && dealer?['businessName'] != 'My Agency');

        if (!user.isVerified && state.matchedLocation == '/auth/setup' && !hasProfileBasics) return null;
        if (!user.isVerified && state.matchedLocation == '/auth/doc-upload') return null;
        if (!user.isVerified && state.matchedLocation == '/auth/pending') return null;
        
        if (!user.isVerified && needsDocUpload) {
          return '/auth/doc-upload';
        }
        if (!user.isVerified && isPending) return '/auth/pending';
        if (!user.isVerified && !hasProfileBasics) return '/auth/setup';


        if (user.isVerified && (state.matchedLocation.startsWith('/auth') || state.matchedLocation == '/splash')) {
          if (user.isFarmer) return '/farmer';
          if (user.isDealer) return '/dealer';
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
      _fadedRoute('/auth/language', const LanguageSelectionScreen()),
      _fadedRoute('/auth/doc-upload', const DocUploadScreen()),
      _fadedRoute('/auth/pending', const PendingApprovalScreen()),


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
      GoRoute(path: '/farmer/trade/book', pageBuilder: (ctx, state) {
        final Map extra = state.extra as Map? ?? {};
        return _fadedPage(TradeBookingScreen(
          cropName: extra['cropName'] ?? '',
          district: extra['district'] ?? '',
          dealerId: extra['dealerId'] ?? '',
        ));
      }),
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
      _fadedRoute('/dealer/slots', const DealerSlotsScreen()),
      _fadedRoute('/dealer/working-days', const DealerWorkingDaysScreen()),
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
