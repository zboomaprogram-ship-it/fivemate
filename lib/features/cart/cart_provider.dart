import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../shared/models/cart_item_model.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItemModel>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<CartItemModel>> {
  late final Box _cartBox;

  CartNotifier() : super([]) {
    _initBox();
  }

  void _initBox() {
    _cartBox = Hive.box('cart_box');
    _loadCart();
  }

  void _loadCart() {
    final List<dynamic>? storedList = _cartBox.get('items');
    if (storedList != null) {
      state = storedList
          .map((item) => CartItemModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }
  }

  void _saveCart() {
    final listToSave = state.map((item) => item.toMap()).toList();
    _cartBox.put('items', listToSave);
  }

  void addItem(CartItemModel newItem) {
    // Check if item already exists
    final index = state.indexWhere((item) => item.id == newItem.id && item.variation == newItem.variation);
    if (index >= 0) {
      // Update quantity
      final existing = state[index];
      state = [
        ...state.sublist(0, index),
        existing.copyWith(quantity: existing.quantity + newItem.quantity),
        ...state.sublist(index + 1),
      ];
    } else {
      // Add new
      state = [...state, newItem];
    }
    _saveCart();
  }

  void updateQuantity(int id, String? variation, int quantity) {
    if (quantity <= 0) {
      removeItem(id, variation);
      return;
    }
    state = state.map((item) {
      if (item.id == id && item.variation == variation) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    _saveCart();
  }

  void removeItem(int id, String? variation) {
    state = state.where((item) => !(item.id == id && item.variation == variation)).toList();
    _saveCart();
  }

  void clearCart() {
    state = [];
    _saveCart();
  }

  double get totalPrice {
    return state.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  int get totalItemsCount {
    return state.fold(0, (sum, item) => sum + item.quantity);
  }
}

final appliedPromoProvider = StateProvider<String?>((ref) {
  return null;
});

final promoDiscountProvider = StateProvider<double>((ref) {
  return 0.0;
});
