import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers/auth_provider.dart';
import '../core/providers/locale_provider.dart';
import '../core/utils/farm_profile_utils.dart';

// Auth
import '../screens/auth/splash_screen.dart';
import '../screens/auth/language_selection_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_screen.dart';

// Farmer
import '../screens/farmer/farm_setup_wizard.dart';
import '../screens/farmer/farmer_home.dart';
import '../screens/farmer/crop_doctor_screen.dart';
import '../screens/farmer/advisory_screen.dart';
import '../screens/farmer/orders_screen.dart';
import '../screens/farmer/order_tracking_screen.dart';
import '../screens/farmer/mandi_news_screen.dart';
import '../screens/farmer/schemes_screen.dart';
import '../screens/farmer/soil_analysis_screen.dart';
import '../screens/farmer/kisan_ai_screen.dart';
import '../screens/farmer/crop_advisor_screen.dart';
import '../screens/farmer/crop_calendar_screen.dart';
import '../screens/farmer/dealer_tab_screen.dart';
import '../screens/farmer/trade_booking_screen.dart';
import '../screens/farmer/farmer_trade_bookings_screen.dart';
import '../screens/farmer/price_alerts_screen.dart';
import '../screens/farmer/pmfby_calculator_screen.dart';
import '../screens/farmer/fpo_bulk_screen.dart';
import '../screens/farmer/equipment_rental_screen.dart';
import '../screens/farmer/farm_tools_screen.dart';
import '../screens/farmer/krishi_tv_screen.dart';
import '../screens/farmer/video_player_screen.dart';
import '../screens/dealer/manage_rates_screen.dart';

// Supplier
import '../screens/supplier/supplier_home.dart';
import '../screens/supplier/supplier_orders_screen.dart';
import '../screens/supplier/add_product_screen.dart';

// Dealer
import '../screens/dealer/dealer_home.dart';
import '../screens/dealer/produce_board_screen.dart';
import '../screens/dealer/make_offer_screen.dart';
import '../screens/dealer/advance_payment_screen.dart';
import '../screens/dealer/my_deals_screen.dart';

// Shared
import '../screens/shared/notifications_screen.dart';
import '../screens/shared/webview_screen.dart';

// Legacy auth screens — not used in v1 farmer app

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      if (state.matchedLocation == '/splash') return null;

      // Wait for secure-storage bootstrap before routing decisions
      if (!authState.isInitialized) return '/splash';

      final languageChosen = ref.read(languageChosenProvider);
      if (!languageChosen && state.matchedLocation != '/auth/language') {
        return '/auth/language';
      }

      // Not authenticated → send directly to Farmer login (V1: farmer-only)
      if (!authState.isAuthenticated && authState.user == null) {
        if (!state.matchedLocation.startsWith('/auth')) return '/auth/login?role=FARMER';
        return null;
      }

      if (authState.isAuthenticated) {
        final user = authState.user!;

        // v1: farmer app only — non-farmers must use farmer login
        if (!user.isFarmer && !state.matchedLocation.startsWith('/auth')) {
          return '/auth/login';
        }

        // Allow legacy transition pages (not OTP — authenticated users must leave auth flow)
        const allowedPaths = ['/auth/pending', '/auth/doc-upload', '/auth/setup'];
        if (allowedPaths.any((p) => state.matchedLocation.startsWith(p))) return null;

        if (user.isFarmer) {
          final setupComplete = authState.farmSetupComplete;
          final loc = state.matchedLocation;

          if (!setupComplete) {
            if (loc == '/farmer/setup') return null;
            if (isFarmSetupGuardedPath(loc)) return '/farmer/setup';
            if (loc == '/farmer' || loc.startsWith('/auth') || loc == '/splash') {
              return '/farmer/setup';
            }
          } else if (loc == '/farmer/setup') {
            return '/farmer';
          }
        }

        // Authenticated farmer → redirect away from auth pages
        if (state.matchedLocation.startsWith('/auth') || state.matchedLocation == '/splash') {
          return '/farmer';
        }
      }
      return null;
    },

    errorBuilder: (ctx, state) => Scaffold(
      backgroundColor: const Color(0xFFF6F1E4),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('Page not found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(state.uri.toString(), style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    ),

    routes: [
      // ── Splash ────────────────────────────────────────
      _faded('/splash', const SplashScreen()),

      // ── Auth ──────────────────────────────────────────
      _faded('/auth/language', const LanguageSelectionScreen()),
      _faded('/auth/login', const LoginScreen()),

      GoRoute(
        path: '/auth/role',
        redirect: (_, __) => '/auth/login',
      ),

      GoRoute(
        path: '/auth/otp',
        pageBuilder: (ctx, state) {
          final q = state.uri.queryParameters;
          return _fadedPage(OtpScreen(
            phone:    q['phone']    ?? '',
            role:     q['role']     ?? 'FARMER',
            language: q['language'] ?? 'en',
          ));
        },
      ),

      GoRoute(
        path: '/auth/signup',
        redirect: (_, __) => '/auth/login',
      ),

      GoRoute(
        path: '/auth/setup',
        redirect: (_, __) => '/auth/login',
      ),
      GoRoute(
        path: '/auth/doc-upload',
        redirect: (_, __) => '/auth/login',
      ),
      GoRoute(
        path: '/auth/pending',
        redirect: (_, __) => '/auth/login',
      ),

      // ── Farmer ────────────────────────────────────────
      _faded('/farmer', const FarmerHome()),
      _faded('/farmer/setup', const FarmSetupWizard()),

      GoRoute(
        path: '/farmer/market',
        redirect: (_, __) => '/farmer/dealer-rates',
      ),

      GoRoute(
        path: '/farmer/market/product/:id',
        redirect: (_, __) => '/farmer',
      ),

      GoRoute(
        path: '/farmer/cart',
        redirect: (_, __) => '/farmer',
      ),

      GoRoute(
        path: '/farmer/payment',
        redirect: (_, __) => '/farmer',
      ),
      GoRoute(
        path: '/farmer/orders',
        redirect: (_, __) => '/farmer',
      ),
      _faded('/farmer/diagnose',   const CropDoctorScreen()),
      _faded('/farmer/advisory',   const AdvisoryScreen()),
      _faded('/farmer/news',       const MandiNewsScreen()),
      _faded('/farmer/tools',      const FarmToolsScreen()),
      _faded('/farmer/schemes',    const SchemesScreen()),
      _faded('/farmer/soil',       const SoilAnalysisScreen()),
      _faded('/farmer/kisan-ai',   const KisanAiScreen()),
      _faded('/farmer/crop-advisor', const CropAdvisorScreen()),
      _faded('/farmer/crop-calendar', const CropCalendarScreen()),
      _faded('/farmer/dealer-rates', const DealerTabScreen()),
      _faded('/farmer/trade/bookings', const FarmerTradeBookingsScreen()),
      _faded('/farmer/price-alerts', const PriceAlertsScreen()),
      _faded('/farmer/pmfby',       const PmfbyCalculatorScreen()),
      _faded('/farmer/fpo-bulk',   const FpoBulkScreen()),
      _faded('/farmer/equipment',  const EquipmentRentalScreen()),
      _faded('/farmer/krishi-tv',   const KrishiTvScreen()),

      GoRoute(
        path: '/farmer/video-player',
        pageBuilder: (ctx, state) {
          final extra = state.extra as Map? ?? {};
          return _fadedPage(VideoPlayerScreen(
            videoId:      extra['videoId']?.toString()      ?? '',
            title:        extra['title']?.toString()        ?? 'Farming Video',
            channel:      extra['channel']?.toString()      ?? 'AgriChannel',
            thumbnailUrl: extra['thumbnailUrl']?.toString(),
          ));
        },
      ),

      GoRoute(
        path: '/farmer/trade/book',
        pageBuilder: (ctx, state) {
          final extra = state.extra as Map? ?? {};
          return _fadedPage(TradeBookingScreen(
            cropName: extra['cropName']?.toString() ?? '',
            district: extra['district']?.toString() ?? '',
            dealerId: extra['dealerId']?.toString() ?? '',
          ));
        },
      ),


      GoRoute(
        path: '/farmer/orders/:id/tracking',
        pageBuilder: (ctx, state) => _fadedPage(
          OrderTrackingScreen(orderId: state.pathParameters['id']!),
        ),
      ),

      // ── Supplier ──────────────────────────────────────
      _faded('/supplier',              const SupplierHome()),
      _faded('/supplier/orders',       const SupplierOrdersScreen()),
      _faded('/supplier/add-product',  const AddProductScreen()),

      // ── Dealer ────────────────────────────────────────
      _faded('/dealer',             const DealerHome()),
      _faded('/dealer/produce-board', const ProduceBoardScreen()),
      _faded('/dealer/my-deals',    const MyDealsScreen()),
      _faded('/dealer/manage-rates', const ManageRatesScreen()),

      GoRoute(
        path: '/dealer/make-offer',
        pageBuilder: (ctx, state) {
          final listing = state.extra as Map? ?? {};
          return _fadedPage(MakeOfferScreen(listing: listing));
        },
      ),

      GoRoute(
        path: '/dealer/advance-payment',
        pageBuilder: (ctx, state) {
          final dealContext = state.extra as Map? ?? {};
          return _fadedPage(AdvancePaymentScreen(dealContext: dealContext));
        },
      ),

      // ── Shared ────────────────────────────────────────
      _faded('/notifications', const NotificationsScreen()),

      GoRoute(
        path: '/webview',
        pageBuilder: (ctx, state) {
          final extra = state.extra as Map? ?? {};
          return _fadedPage(WebViewScreen(
            url: extra['url']?.toString() ?? 'https://google.com',
            title: extra['title']?.toString() ?? 'Article',
          ));
        },
      ),

      // ── Legacy / Fallback ─────────────────────────────
      GoRoute(
        path: '/farmer/shop',
        redirect: (_, __) => '/farmer',
      ),

      GoRoute(
        path: '/farmer/checkout',
        redirect: (_, __) => '/farmer',
      ),

      // Legacy orders screen (the new one is /farmer/orders)
      _faded('/farmer/orders-legacy', const OrdersScreen()),
    ],
  );

  ref.listen(authProvider, (previous, next) {
    if (previous?.isAuthenticated != next.isAuthenticated ||
        previous?.user?.id != next.user?.id ||
        previous?.farmSetupComplete != next.farmSetupComplete ||
        previous?.isInitialized != next.isInitialized) {
      router.refresh();
    }
  });

  ref.listen(languageChosenProvider, (previous, next) {
    if (previous != next) router.refresh();
  });

  return router;
});

// ── Helpers ───────────────────────────────────────────────

GoRoute _faded(String path, Widget child) {
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
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
    },
  );
}

