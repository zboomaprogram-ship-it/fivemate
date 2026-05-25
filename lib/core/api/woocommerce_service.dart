import 'package:hive/hive.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'api_client.dart';
import '../../shared/models/product_model.dart';
import '../../shared/models/category_model.dart';

class WooCommerceService {
  final ApiClient _apiClient;

  WooCommerceService(this._apiClient);

  // Fetch list of products with pagination, search, and category filtering
  Future<List<ProductModel>> getProducts({
    int page = 1,
    int perPage = 10,
    String? search,
    int? categoryId,
    String? orderBy, // 'date' or 'price'
    String? order, // 'asc' or 'desc'
  }) async {
    final isDefaultQuery = page == 1 &&
        (search == null || search.isEmpty) &&
        categoryId == null &&
        orderBy == null;

    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (categoryId != null) {
        queryParams['category'] = categoryId;
      }
      if (orderBy != null) {
        queryParams['orderby'] = orderBy;
      }
      if (order != null) {
        queryParams['order'] = order;
      }

      final response = await _apiClient.dio.get(
        '/wc/store/v1/products',
        queryParameters: queryParams,
      );

      if (response.data is List) {
        final List list = response.data;
        final products = list.map((item) => ProductModel.fromJson(item)).toList();

        // Cache default landing page query for offline use
        if (isDefaultQuery) {
          try {
            final box = Hive.box('cache_box');
            await box.put('cached_products_page_1', list);
          } catch (_) {}
        }

        return products;
      }
      return [];
    } catch (e) {
      // Fallback to cache if offline for default query
      if (isDefaultQuery) {
        try {
          final box = Hive.box('cache_box');
          final cachedData = box.get('cached_products_page_1');
          if (cachedData is List) {
            return cachedData.map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item))).toList();
          }
        } catch (_) {}
      }
      rethrow;
    }
  }

  // Fetch list of categories
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _apiClient.dio.get('/wc/store/v1/products/categories', queryParameters: {
        'per_page': 100, // Fetch all categories
      });

      if (response.data is List) {
        final List list = response.data;
        final categories = list
            .map((item) => CategoryModel.fromJson(item))
            .where((cat) => cat.name != 'Uncategorized' && cat.name != 'غير مصنف') // Filter default WP categories
            .toList();

        try {
          final box = Hive.box('cache_box');
          await box.put('cached_categories', list);
        } catch (_) {}

        return categories;
      }
      return [];
    } catch (e) {
      // Fallback to cache if offline
      try {
        final box = Hive.box('cache_box');
        final cachedData = box.get('cached_categories');
        if (cachedData is List) {
          return cachedData
              .map((item) => CategoryModel.fromJson(Map<String, dynamic>.from(item)))
              .where((cat) => cat.name != 'Uncategorized' && cat.name != 'غير مصنف')
              .toList();
        }
      } catch (_) {}
      rethrow;
    }
  }

  // Fetch single product details
  Future<ProductModel?> getProductById(int id) async {
    try {
      final response = await _apiClient.dio.get('/wc/store/v1/products/$id');
      if (response.data != null && response.data is Map<String, dynamic>) {
        final product = ProductModel.fromJson(response.data);

        try {
          final box = Hive.box('cache_box');
          final Map<dynamic, dynamic> cachedMap = box.get('cached_product_details', defaultValue: <dynamic, dynamic>{});
          final newMap = Map<String, dynamic>.from(cachedMap);
          newMap[id.toString()] = response.data;
          await box.put('cached_product_details', newMap);
        } catch (_) {}

        return product;
      }
      return null;
    } catch (e) {
      // Fallback to cache if offline
      try {
        final box = Hive.box('cache_box');
        final Map<dynamic, dynamic> cachedMap = box.get('cached_product_details', defaultValue: <dynamic, dynamic>{});
        if (cachedMap.containsKey(id.toString())) {
          final item = cachedMap[id.toString()];
          if (item is Map) {
            return ProductModel.fromJson(Map<String, dynamic>.from(item));
          }
        }
      } catch (_) {}
      rethrow;
    }
  }

  // Fetch a random product ID from WordPress and load its details
  Future<ProductModel?> getRandomProduct() async {
    try {
      final response = await _apiClient.dio.get('/app/v1/random-product');
      if (response.data != null && response.data is Map<String, dynamic>) {
        final id = response.data['id'] as int;
        return getProductById(id);
      }
    } catch (e) {
      // Local fallback: fetch standard products list and pick a random one
      try {
        final productsList = await getProducts(page: 1, perPage: 20);
        if (productsList.isNotEmpty) {
          productsList.shuffle();
          return productsList.first;
        }
      } catch (_) {}
    }
    return null;
  }

  // Subscribe user's OneSignal Subscription ID to a product stock alert
  Future<bool> subscribeToStockAlert(int productId) async {
    final subscriptionId = OneSignal.User.pushSubscription.id;
    if (subscriptionId == null || subscriptionId.isEmpty) {
      throw Exception('notifications_disabled');
    }

    final response = await _apiClient.dio.post(
      '/app/v1/stock-alert',
      data: {
        'product_id': productId,
        'player_id': subscriptionId,
      },
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  // Fetch multiple products by their specific IDs
  Future<List<ProductModel>> getProductsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    try {
      final response = await _apiClient.dio.get(
        '/wc/store/v1/products',
        queryParameters: {
          'include': ids.join(','),
        },
      );
      if (response.data is List) {
        final List list = response.data;
        return list.map((item) => ProductModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      // Fallback: fetch them one by one
      final list = <ProductModel>[];
      for (final id in ids) {
        try {
          final prod = await getProductById(id);
          if (prod != null) list.add(prod);
        } catch (_) {}
      }
      return list;
    }
  }

  // Fetch loyalty points based on billing phone number from the server
  Future<Map<String, dynamic>?> getLoyaltyPoints(String phone) async {
    try {
      final response = await _apiClient.dio.get(
        '/app/v1/loyalty-points',
        queryParameters: {
          'phone': phone,
        },
      );
      if (response.data != null && response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (_) {}
    return null;
  }
}

