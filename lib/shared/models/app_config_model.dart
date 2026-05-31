class AppConfigModel {
  final String whatsappNumber;
  final String whatsappTextTemplate;
  final bool maintenanceMode;
  final List<String> banners;
  final List<int> featuredCategoryIds;
  final String supportEmail;
  final String forceUpdateVersion;
  final bool customOrderEnabled;
  final String collectionName;
  final String collectionLaunchDate;
  final String collectionTeaserImage;
  final String onesignalAppId;
  final List<String> styleGallery;

  AppConfigModel({
    required this.whatsappNumber,
    required this.whatsappTextTemplate,
    required this.maintenanceMode,
    required this.banners,
    required this.featuredCategoryIds,
    required this.supportEmail,
    required this.forceUpdateVersion,
    required this.customOrderEnabled,
    required this.collectionName,
    required this.collectionLaunchDate,
    required this.collectionTeaserImage,
    required this.onesignalAppId,
    required this.styleGallery,
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    return AppConfigModel(
      whatsappNumber:
          json['whatsapp_number'] ?? '201092970736', // Fallback default
      whatsappTextTemplate:
          json['whatsapp_text_template'] ??
          json['whatsapp_greeting'] ??
          'مرحباً متجر خامات، أود تأكيد الطلب التالي:\n\n*الاسم:* {name}\n*الهاتف:* {phone}\n*المحافظة:* {governorate}\n*العنوان:* {address}\n\n*المنتجات:* \n{items}\n\n*المجموع الإجمالي:* {total} ج.م',
      maintenanceMode: json['maintenance_mode'] ?? false,
      banners: List<String>.from(json['banners'] ?? []),
      featuredCategoryIds: List<int>.from(json['featured_category_ids'] ?? []),
      supportEmail: json['support_email'] ?? 'support@5amat-handmade.com',
      forceUpdateVersion: json['force_update_version'] ?? '1.0.0',
      customOrderEnabled: json['custom_order_enabled'] ?? true,
      collectionName: json['collection_name'] ?? 'مجموعة الصيف الجديد',
      collectionLaunchDate:
          json['collection_launch_date'] ??
          DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      collectionTeaserImage:
          json['collection_teaser_image'] ??
          'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?q=80&w=600',
      onesignalAppId:
          json['onesignal_app_id'] ?? '5amat-onesignal-placeholder-app-id',
      styleGallery: List<String>.from(json['style_gallery'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'whatsapp_number': whatsappNumber,
      'whatsapp_text_template': whatsappTextTemplate,
      'maintenance_mode': maintenanceMode,
      'banners': banners,
      'featured_category_ids': featuredCategoryIds,
      'support_email': supportEmail,
      'force_update_version': forceUpdateVersion,
      'custom_order_enabled': customOrderEnabled,
      'collection_name': collectionName,
      'collection_launch_date': collectionLaunchDate,
      'collection_teaser_image': collectionTeaserImage,
      'onesignal_app_id': onesignalAppId,
      'style_gallery': styleGallery,
    };
  }

  // Pre-configured fallback settings to keep app fully functional
  static AppConfigModel get localFallback {
    return AppConfigModel(
      whatsappNumber: '201201236547', // Egyptian phone number
      whatsappTextTemplate:
          'مرحباً متجر خامات، أود تأكيد الطلب التالي:\n\n*الاسم:* {name}\n*الهاتف:* {phone}\n*المحافظة:* {governorate}\n*العنوان:* {address}\n\n*المنتجات:* \n{items}\n\n*المجموع الإجمالي:* {total} ج.م',
      maintenanceMode: false,
      banners: [
        'https://5amat-handmade.com/wp-content/uploads/2026/03/%D8%AE%D8%A7%D9%85%D8%A7%D8%AA.png',
        'https://5amat-handmade.com/wp-content/uploads/2026/03/resin.png',
        'https://5amat-handmade.com/wp-content/uploads/2026/03/%D8%A7%D8%AE%D8%B4%D8%A7%D8%A7%D8%A8.png',
      ],
      featuredCategoryIds: [175, 176, 178], // Molds, resin, concrete
      supportEmail: '5amathandmade@gmail.com',
      forceUpdateVersion: '1.0.0',
      customOrderEnabled: true,
      collectionName: 'مجموعة الصيف الجديد',
      collectionLaunchDate: DateTime.now()
          .add(const Duration(days: 7))
          .toIso8601String(),
      collectionTeaserImage:
          'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?q=80&w=600',
      onesignalAppId: '5amat-onesignal-placeholder-app-id',
      styleGallery: [
        'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?q=80&w=600',
        'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?q=80&w=600',
        'https://images.unsplash.com/photo-1605100804763-247f67b3557e?q=80&w=600',
        'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?q=80&w=600',
      ],
    );
  }
}
