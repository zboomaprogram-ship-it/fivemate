import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../utils/onesignal_helper.dart';
import 'api_client.dart';
import '../../shared/models/app_config_model.dart';

class AppConfigService {
  final ApiClient _apiClient;

  AppConfigService(this._apiClient);

  Future<AppConfigModel> fetchAppConfig() async {
    try {
      final response = await _apiClient.dio.get('/app/v1/config');
      if (response.statusCode == 200 && response.data != null && response.data is Map<String, dynamic>) {
        final config = AppConfigModel.fromJson(response.data);

        // Dynamically initialize/update OneSignal helper with the actual App ID from WordPress Settings
        if (config.onesignalAppId.isNotEmpty && config.onesignalAppId != '5amat-onesignal-placeholder-app-id') {
          OneSignalHelper.initialize(config.onesignalAppId);
        } else {
          print('OneSignal: No dynamic App ID configured or still using placeholder.');
        }

        try {
          final box = Hive.box('cache_box');
          await box.put('cached_app_config', response.data);
        } catch (_) {}

        return config;
      }
      return _getLocalOrCachedFallback();
    } on DioException catch (dioErr) {
      print('Config endpoint error: ${dioErr.message}');
      return _getLocalOrCachedFallback();
    } catch (e) {
      print('General config error: $e');
      return _getLocalOrCachedFallback();
    }
  }

  AppConfigModel? getCachedConfig() {
    try {
      final box = Hive.box('cache_box');
      final cachedData = box.get('cached_app_config');
      if (cachedData is Map) {
        final config = AppConfigModel.fromJson(Map<String, dynamic>.from(cachedData));
        if (config.onesignalAppId.isNotEmpty && config.onesignalAppId != '5amat-onesignal-placeholder-app-id') {
          OneSignalHelper.initialize(config.onesignalAppId);
        }
        return config;
      }
    } catch (_) {}
    return null;
  }

  AppConfigModel _getLocalOrCachedFallback() {
    return getCachedConfig() ?? AppConfigModel.localFallback;
  }
}

