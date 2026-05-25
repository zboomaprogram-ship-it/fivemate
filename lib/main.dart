import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_links/app_links.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/utils/onesignal_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase Core
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Initialize Local Hive boxes
  await Hive.initFlutter();
  await Hive.openBox('prefs_box');
  await Hive.openBox('cart_box');
  await Hive.openBox('favourites_box');
  await Hive.openBox('orders_box');
  await Hive.openBox('cache_box');

  // Initialize OneSignal Notifications if a real App ID was defined at compile-time
  const envAppId = String.fromEnvironment('ONESIGNAL_APP_ID');
  if (envAppId.isNotEmpty && envAppId != "5amat-onesignal-placeholder-app-id") {
    OneSignalHelper.initialize(envAppId);
  }

  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final AppLinks _appLinks;
  dynamic _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      final path = uri.path;
      final queryParams = uri.queryParameters;

      if (path.startsWith('/product/')) {
        final id = path.split('/').last;
        AppRouter.router.push('/shop/product/$id');
      } else if (path.startsWith('/shop/product/')) {
        final id = path.split('/').last;
        AppRouter.router.push('/shop/product/$id');
      } else if (path == '/wishlist') {
        final ids = queryParams['ids'] ?? '';
        AppRouter.router.push('/wishlist?ids=$ids');
      } else if (path == '/style-gallery') {
        AppRouter.router.push('/style-gallery');
      } else if (path == '/custom-order') {
        AppRouter.router.push('/custom-order');
      }
    }, onError: (err) {
      debugPrint('Deep Link error: $err');
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'خامات هاند ميد',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      
      // Route Mappings
      routerConfig: AppRouter.router,

      // Force Arabic RTL layout out-of-the-box
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [
        Locale('ar', 'EG'), // Arabic - Egypt
        Locale('en', 'US'), // English - US
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
