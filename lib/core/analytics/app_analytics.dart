import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/product_model.dart';
import '../../shared/models/cart_item_model.dart';

class AppAnalytics {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static FirebaseAnalytics get instance => _analytics;

  /// Log screen views manually if needed
  static Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
      debugPrint('Analytics: Screen View logged -> $screenName');
    } catch (e) {
      debugPrint('Analytics Error logScreenView: $e');
    }
  }

  /// Log when a user views a specific product
  static Future<void> logProductView(ProductModel product) async {
    try {
      await _analytics.logViewItem(
        currency: 'EGP',
        value: product.price,
        items: [
          AnalyticsEventItem(
            itemId: product.id.toString(),
            itemName: product.name,
            itemCategory: product.categories.isNotEmpty ? product.categories.first : 'General',
            price: num.tryParse(product.price.toString()),
            quantity: 1,
          ),
        ],
      );
      debugPrint('Analytics: View Item logged -> ${product.name} (${product.id})');
    } catch (e) {
      debugPrint('Analytics Error logProductView: $e');
    }
  }

  /// Log when a user adds an item to their shopping cart
  static Future<void> logAddToCart(ProductModel product, int quantity) async {
    try {
      await _analytics.logAddToCart(
        currency: 'EGP',
        value: product.price * quantity,
        items: [
          AnalyticsEventItem(
            itemId: product.id.toString(),
            itemName: product.name,
            itemCategory: product.categories.isNotEmpty ? product.categories.first : 'General',
            price: num.tryParse(product.price.toString()),
            quantity: quantity,
          ),
        ],
      );
      debugPrint('Analytics: Add To Cart logged -> ${product.name} (Qty: $quantity)');
    } catch (e) {
      debugPrint('Analytics Error logAddToCart: $e');
    }
  }

  /// Log when a user removes an item from their shopping cart
  static Future<void> logRemoveFromCart(ProductModel product, int quantity) async {
    try {
      await _analytics.logRemoveFromCart(
        currency: 'EGP',
        value: product.price * quantity,
        items: [
          AnalyticsEventItem(
            itemId: product.id.toString(),
            itemName: product.name,
            itemCategory: product.categories.isNotEmpty ? product.categories.first : 'General',
            price: num.tryParse(product.price.toString()),
            quantity: quantity,
          ),
        ],
      );
      debugPrint('Analytics: Remove From Cart logged -> ${product.name} (Qty: $quantity)');
    } catch (e) {
      debugPrint('Analytics Error logRemoveFromCart: $e');
    }
  }

  /// Log when a user adds an item to their wishlist
  static Future<void> logAddToWishlist(ProductModel product) async {
    try {
      await _analytics.logAddToWishlist(
        value: product.price,
        currency: 'EGP',
        items: [
          AnalyticsEventItem(
            itemId: product.id.toString(),
            itemName: product.name,
            itemCategory: product.categories.isNotEmpty ? product.categories.first : 'General',
            price: num.tryParse(product.price.toString()),
          ),
        ],
      );
      debugPrint('Analytics: Add To Wishlist logged -> ${product.name}');
    } catch (e) {
      debugPrint('Analytics Error logAddToWishlist: $e');
    }
  }

  /// Log when a user removes an item from their wishlist
  static Future<void> logRemoveFromWishlist(ProductModel product) async {
    try {
      // Firebase doesn't have a standard remove_from_wishlist event, so we use a custom event
      await _analytics.logEvent(
        name: 'remove_from_wishlist',
        parameters: {
          'item_id': product.id.toString(),
          'item_name': product.name,
          'value': product.price,
          'currency': 'EGP',
        },
      );
      debugPrint('Analytics: Remove From Wishlist logged -> ${product.name}');
    } catch (e) {
      debugPrint('Analytics Error logRemoveFromWishlist: $e');
    }
  }

  /// Log when a user enters the checkout screen
  static Future<void> logBeginCheckout(List<CartItemModel> items, double total) async {
    try {
      final eventItems = items.map((item) {
        return AnalyticsEventItem(
          itemId: item.id.toString(),
          itemName: item.name,
          price: num.tryParse(item.price.toString()),
          quantity: item.quantity,
        );
      }).toList();

      await _analytics.logBeginCheckout(
        value: total,
        currency: 'EGP',
        items: eventItems,
      );
      debugPrint('Analytics: Begin Checkout logged with ${items.length} items (Total: $total)');
    } catch (e) {
      debugPrint('Analytics Error logBeginCheckout: $e');
    }
  }

  /// Log when a purchase is completed (redirected to WhatsApp)
  static Future<void> logPurchase({
    required List<CartItemModel> items,
    required double total,
    required String name,
    required String phone,
  }) async {
    try {
      final eventItems = items.map((item) {
        return AnalyticsEventItem(
          itemId: item.id.toString(),
          itemName: item.name,
          price: num.tryParse(item.price.toString()),
          quantity: item.quantity,
        );
      }).toList();

      // Generate a simple unique transaction ID
      final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';

      await _analytics.logPurchase(
        transactionId: transactionId,
        value: total,
        currency: 'EGP',
        items: eventItems,
      );

      // Also log custom properties if desired
      await _analytics.logEvent(
        name: 'whatsapp_checkout_complete',
        parameters: {
          'transaction_id': transactionId,
          'buyer_name': name,
          'buyer_phone': phone,
          'total_value': total,
          'item_count': items.fold<int>(0, (sum, i) => sum + i.quantity),
        },
      );
      debugPrint('Analytics: Purchase/WhatsApp Redirect logged -> Txn: $transactionId');
    } catch (e) {
      debugPrint('Analytics Error logPurchase: $e');
    }
  }

  /// Log search query
  static Future<void> logSearch(String query) async {
    try {
      if (query.trim().isEmpty) return;
      await _analytics.logSearch(searchTerm: query);
      debugPrint('Analytics: Search Term logged -> $query');
    } catch (e) {
      debugPrint('Analytics Error logSearch: $e');
    }
  }
}
