import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/woocommerce_service.dart';
import '../../core/api/app_config_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final woocommerceServiceProvider = Provider<WooCommerceService>((ref) {
  final client = ref.watch(apiClientProvider);
  return WooCommerceService(client);
});

final appConfigServiceProvider = Provider<AppConfigService>((ref) {
  final client = ref.watch(apiClientProvider);
  return AppConfigService(client);
});
