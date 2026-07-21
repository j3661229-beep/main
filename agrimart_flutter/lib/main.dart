import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/storage/offline_cache.dart';
import 'core/widgets/error_boundary.dart';
import 'core/utils/responsive.dart';
import 'core/providers/locale_provider.dart';
import 'core/constants/indian_languages.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:agrimart/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  await Hive.openBox('app_cache');
  await OfflineCache.init();

  final bootstrap = await loadLocaleBootstrap();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => LocaleNotifier(ref, initialLocale: bootstrap.locale)),
        languageChosenProvider.overrideWith((ref) => LanguageChosenNotifier(initial: bootstrap.languageChosen)),
      ],
      child: const ErrorBoundary(
        child: AgriMartApp(),
      ),
    ),
  );
}

class AgriMartApp extends ConsumerWidget {
  const AgriMartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'AgriMart',
      theme: AppTheme.light,
      routerConfig: router,
      locale: locale,
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (IndianLanguages.isSupported(locale.languageCode)) {
          return locale;
        }
        if (deviceLocale != null && IndianLanguages.isSupported(deviceLocale.languageCode)) {
          return Locale(deviceLocale.languageCode);
        }
        return supportedLocales.first;
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: IndianLanguages.locales,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return Localizations.override(
          context: context,
          locale: locale,
          child: MediaQuery(
            data: mq.copyWith(textScaler: TextScaler.linear(1.0)),
            child: ResponsivePage(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
    );
  }
}
