import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final favouritesProvider = StateNotifierProvider<FavouritesNotifier, List<int>>((ref) {
  return FavouritesNotifier();
});

class FavouritesNotifier extends StateNotifier<List<int>> {
  late final Box _box;

  FavouritesNotifier() : super([]) {
    _initBox();
  }

  void _initBox() {
    _box = Hive.box('favourites_box');
    _loadFavourites();
  }

  void _loadFavourites() {
    final List<dynamic>? storedList = _box.get('ids');
    if (storedList != null) {
      state = List<int>.from(storedList);
    }
  }

  void _saveFavourites() {
    _box.put('ids', state);
  }

  void toggleFavourite(int productId) {
    if (state.contains(productId)) {
      state = state.where((id) => id != productId).toList();
    } else {
      state = [...state, productId];
    }
    _saveFavourites();
  }

  bool isFavourite(int productId) {
    return state.contains(productId);
  }
}
