import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/shop/shop_screen.dart';
import '../../features/product_detail/product_detail_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/checkout/checkout_screen.dart';
import '../../features/favourites/favourites_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../shared/widgets/main_navigation_scaffold.dart';
import '../../features/custom_order/custom_order_screen.dart';
import '../../features/favourites/wishlist_share_screen.dart';
import '../../features/lookbook/style_gallery_screen.dart';


final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final GlobalKey<NavigatorState> _shopNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shop');
final GlobalKey<NavigatorState> _favNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'fav');
final GlobalKey<NavigatorState> _cartNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'cart');
final GlobalKey<NavigatorState> _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    observers: [
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
    ],
    routes: [
      // Splash Route
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      // Onboarding Route
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Custom Order Route
      GoRoute(
        path: '/custom-order',
        builder: (context, state) => const CustomOrderScreen(),
      ),
      // Wishlist Deep-Link / Share Route
      GoRoute(
        path: '/wishlist',
        builder: (context, state) {
          final ids = state.uri.queryParameters['ids'] ?? '';
          return WishlistShareScreen(idsStr: ids);
        },
      ),
      // Lookbook Style Gallery Route
      GoRoute(
        path: '/style-gallery',
        builder: (context, state) => const StyleGalleryScreen(),
      ),
      // Stateful Shell Tab Routes
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Branch Home
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Branch Shop
          StatefulShellBranch(
            navigatorKey: _shopNavigatorKey,
            routes: [
              GoRoute(
                path: '/shop',
                builder: (context, state) => const ShopScreen(),
                routes: [
                  // Product details (nested in Shop stack)
                  GoRoute(
                    path: 'product/:id',
                    parentNavigatorKey: _rootNavigatorKey, // Open over bottom bar
                    builder: (context, state) {
                      final idStr = state.pathParameters['id'] ?? '0';
                      final id = int.tryParse(idStr) ?? 0;
                      return ProductDetailScreen(productId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch Favourites
          StatefulShellBranch(
            navigatorKey: _favNavigatorKey,
            routes: [
              GoRoute(
                path: '/favourites',
                builder: (context, state) => const FavouritesScreen(),
              ),
            ],
          ),
          // Branch Cart
          StatefulShellBranch(
            navigatorKey: _cartNavigatorKey,
            routes: [
              GoRoute(
                path: '/cart',
                builder: (context, state) => const CartScreen(),
                routes: [
                  // Checkout (nested in Cart stack)
                  GoRoute(
                    path: 'checkout',
                    parentNavigatorKey: _rootNavigatorKey, // Open over bottom bar
                    builder: (context, state) => const CheckoutScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Branch Profile
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
