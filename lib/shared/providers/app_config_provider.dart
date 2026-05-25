import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_providers.dart';
import '../models/app_config_model.dart';

final appConfigProvider = FutureProvider<AppConfigModel>((ref) async {
  final service = ref.watch(appConfigServiceProvider);
  return await service.fetchAppConfig();
});
