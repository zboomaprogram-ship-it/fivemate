import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../router/app_router.dart';

class OneSignalHelper {
  static bool _initialized = false;

  static void initialize(String appId) {
    if (_initialized) {
      print('OneSignal: Already initialized, skipping dynamic init.');
      return;
    }
    if (appId.isEmpty || appId == '5amat-onesignal-placeholder-app-id') {
      print('OneSignal: App ID is empty or placeholder, delaying initialization.');
      return;
    }

    try {
      print('OneSignal: Initializing OneSignal with App ID: $appId');
      
      // Enable verbose logging in debug mode
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      
      // Initialize OneSignal
      OneSignal.initialize(appId);
      
      // Request notification permission
      OneSignal.Notifications.requestPermission(true).then((accepted) {
        print('OneSignal: Notification permission status: $accepted');
        print('OneSignal: Device Subscription ID: ${OneSignal.User.pushSubscription.id}');
        print('OneSignal: Device Push Token: ${OneSignal.User.pushSubscription.token}');
      });

      // Handle OneSignal deep linking
      OneSignal.Notifications.addClickListener((event) {
        final deepLink = event.notification.additionalData?['deep_link'] as String?;
        if (deepLink != null && deepLink.isNotEmpty) {
          try {
            final uri = Uri.parse(deepLink);
            String path = uri.path;
            
            if (uri.scheme == '5amat') {
              String targetPath = '';
              if (uri.host == 'product') {
                final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
                targetPath = '/shop/product/$id';
              } else if (uri.host == 'shop') {
                final catId = uri.queryParameters['catId'] ?? uri.queryParameters['categoryId'];
                targetPath = catId != null ? '/shop?catId=$catId' : '/shop';
              } else if (uri.host == 'category') {
                final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
                targetPath = '/shop?catId=$id';
              } else if (uri.host == 'wishlist') {
                final ids = uri.queryParameters['ids'] ?? '';
                targetPath = '/wishlist?ids=$ids';
              } else if (uri.host == 'style-gallery') {
                targetPath = '/style-gallery';
              } else if (uri.host == 'custom-order') {
                targetPath = '/custom-order';
              } else if (uri.host == 'home' || uri.host == '') {
                targetPath = '/home';
              } else {
                targetPath = '/${uri.host}${uri.path}';
              }
              AppRouter.router.push(targetPath);
            } else {
              if (path.startsWith('/product/')) {
                final id = path.split('/').last;
                AppRouter.router.push('/shop/product/$id');
              } else if (path.startsWith('/shop/product/')) {
                final id = path.split('/').last;
                AppRouter.router.push('/shop/product/$id');
              } else if (path == '/wishlist') {
                final ids = uri.queryParameters['ids'] ?? '';
                AppRouter.router.push('/wishlist?ids=$ids');
              } else if (path == '/style-gallery') {
                AppRouter.router.push('/style-gallery');
              } else if (path == '/custom-order') {
                AppRouter.router.push('/custom-order');
              } else if (path == '/shop') {
                final catId = uri.queryParameters['catId'];
                AppRouter.router.push(catId != null ? '/shop?catId=$catId' : '/shop');
              } else if (path == '/home') {
                AppRouter.router.push('/home');
              } else if (path.isNotEmpty && path != '/') {
                AppRouter.router.push(path);
              }
            }
          } catch (err) {
            debugPrint('Error parsing OneSignal deep link: $err');
          }
        }
      });

      _initialized = true;
      print('OneSignal: Setup completed successfully.');
    } catch (e) {
      print('OneSignal: Error initializing OneSignal helper: $e');
    }
  }
}
