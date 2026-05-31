import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_providers.dart';
import '../models/app_config_model.dart';

final appConfigProvider = StreamProvider<AppConfigModel>((ref) async* {
  final service = ref.watch(appConfigServiceProvider);
  
  // 1. Yield cached configuration immediately if available
  final cached = service.getCachedConfig();
  if (cached != null) {
    yield cached;
  }
  
  // 2. Fetch from network and yield updated value
  try {
    final networkConfig = await service.fetchAppConfig();
    yield networkConfig;
  } catch (e) {
    // If cached was null, yield local fallback
    if (cached == null) {
      yield AppConfigModel.localFallback;
    }
  }
});
