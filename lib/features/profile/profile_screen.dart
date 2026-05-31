import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/providers/api_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final Box _prefsBox;
  late final Box _ordersBox;

  String _name = '';
  String _phone = '';
  String _address = '';
  String _governorate = '';
  List<dynamic> _orders = [];
  int? _verifiedPoints;
  bool _isLoadingPoints = false;

  @override
  void initState() {
    super.initState();
    _prefsBox = Hive.box('prefs_box');
    _ordersBox = Hive.box('orders_box');
    _loadProfileData();
  }

  void _loadProfileData() {
    setState(() {
      _name = _prefsBox.get('client_name', defaultValue: '');
      _phone = _prefsBox.get('client_phone', defaultValue: '');
      _address = _prefsBox.get('client_address', defaultValue: '');
      _governorate = _prefsBox.get('client_governorate', defaultValue: '');
      _orders = _ordersBox.get('history', defaultValue: []);
    });
    if (_phone.isNotEmpty) {
      _fetchVerifiedPoints();
    }
  }

  Future<void> _fetchVerifiedPoints() async {
    if (_isLoadingPoints) return;
    setState(() {
      _isLoadingPoints = true;
    });
    try {
      final service = ref.read(woocommerceServiceProvider);
      final result = await service.getLoyaltyPoints(_phone);
      if (result != null && mounted) {
        setState(() {
          _verifiedPoints = result['points'] as int?;
        });
      }
    } catch (_) {
      // Fallback
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPoints = false;
        });
      }
    }
  }

  Future<void> _clearOrderHistory() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح السجل؟', textAlign: TextAlign.right),
        content: const Text(
          'هل أنت متأكد من رغبتك في حذف سجل الطلبات بالكامل؟',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await _ordersBox.put('history', []);
              Navigator.pop(context);
              _loadProfileData();
            },
            child: const Text(
              'نعم، مسح السجل',
              style: TextStyle(color: AppColors.alert),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        actions: [
          if (_orders.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: AppColors.textMedium),
              onPressed: _clearOrderHistory,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Avatar Card
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.transparent,
                      backgroundImage: AssetImage('assets/logo.png'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _name.isNotEmpty ? _name : 'زائر متجر خامات',
                      style: AppTextStyles.h2,
                      textAlign: TextAlign.center,
                    ),
                    if (_phone.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _phone,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMedium,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            _buildLoyaltyCard(),
            const SizedBox(height: 24),

            // Shipping Info Details
            const Text('بيانات الشحن الافتراضية', style: AppTextStyles.h2),
            const SizedBox(height: 12),
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _name.isEmpty && _address.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          'لم يتم حفظ أي بيانات شحن بعد. سيتم حفظ بياناتك تلقائياً عند إتمام أول طلب شحن.',
                          style: AppTextStyles.body,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            Icons.person_outline,
                            'الاسم الكامل',
                            _name,
                          ),
                          const Divider(
                            height: 20,
                            color: AppColors.borderLight,
                          ),
                          _buildDetailRow(
                            Icons.phone_iphone_outlined,
                            'الهاتف',
                            _phone,
                          ),
                          const Divider(
                            height: 20,
                            color: AppColors.borderLight,
                          ),
                          _buildDetailRow(
                            Icons.map_outlined,
                            'المحافظة',
                            _governorate,
                          ),
                          const Divider(
                            height: 20,
                            color: AppColors.borderLight,
                          ),
                          _buildDetailRow(
                            Icons.location_on_outlined,
                            'العنوان بالتفصيل',
                            _address,
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Local Order History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('سجل الطلبات الأخير', style: AppTextStyles.h2),
                if (_orders.isNotEmpty)
                  Text(
                    '(${_orders.length} طلب)',
                    style: AppTextStyles.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_orders.isEmpty)
              Card(
                color: AppColors.surface,
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 32.0,
                    horizontal: 16.0,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 40,
                        color: AppColors.textLight,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'لا توجد طلبات سابقة مسجلة في هذا الجهاز.',
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  // Show newer orders first
                  final order = _orders[_orders.length - 1 - index];
                  final date =
                      DateTime.tryParse(order['date'] ?? '') ?? DateTime.now();
                  final formattedDate =
                      '${date.year}/${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formattedDate,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'تم الإرسال للواتساب',
                                  style: TextStyle(
                                    color: AppColors.secondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(
                            height: 20,
                            color: AppColors.borderLight,
                          ),
                          Text(
                            order['items_summary'] ?? '',
                            style: AppTextStyles.body.copyWith(fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Divider(
                            height: 20,
                            color: AppColors.borderLight,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () async {
                                        final phone = order['phone'] ?? '';
                                        final name = order['name'] ?? '';
                                        final msg = Uri.encodeComponent(
                                          'مرحباً متجر خامات، أود الاستفسار عن حالة طلبي المرسل بتاريخ $formattedDate.\n\nالاسم: $name\nالهاتف: $phone',
                                        );
                                        final box = Hive.box('cache_box');
                                        final cachedConfig = box.get(
                                          'cached_config',
                                        );
                                        String whatsappNum = '201099684347';
                                        if (cachedConfig is Map &&
                                            cachedConfig['whatsapp_number'] !=
                                                null) {
                                          whatsappNum =
                                              cachedConfig['whatsapp_number']
                                                  .toString();
                                        }
                                        final url =
                                            'https://wa.me/$whatsappNum?text=$msg';
                                        if (await url_launcher.canLaunchUrl(
                                          Uri.parse(url),
                                        )) {
                                          await url_launcher.launchUrl(
                                            Uri.parse(url),
                                            mode: url_launcher
                                                .LaunchMode
                                                .externalApplication,
                                          );
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.support_agent,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      label: const Text(
                                        'تتبع الطلب',
                                        style: TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 11,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (order['message'] != null)
                                      TextButton.icon(
                                        onPressed: () async {
                                          final box = Hive.box('cache_box');
                                          final cachedConfig = box.get(
                                            'cached_config',
                                          );
                                          String whatsappNum = '201092970736';
                                          if (cachedConfig is Map &&
                                              cachedConfig['whatsapp_number'] !=
                                                  null) {
                                            whatsappNum =
                                                cachedConfig['whatsapp_number']
                                                    .toString();
                                          }
                                          final msg = Uri.encodeComponent(
                                            order['message'],
                                          );
                                          final url =
                                              'https://wa.me/$whatsappNum?text=$msg';
                                          if (await url_launcher.canLaunchUrl(
                                            Uri.parse(url),
                                          )) {
                                            await url_launcher.launchUrl(
                                              Uri.parse(url),
                                              mode: url_launcher
                                                  .LaunchMode
                                                  .externalApplication,
                                            );
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.send_rounded,
                                          size: 12,
                                          color: AppColors.secondary,
                                        ),
                                        label: const Text(
                                          'إعادة الإرسال',
                                          style: TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 11,
                                            color: AppColors.secondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(order['total'] as num?)?.toStringAsFixed(2) ?? '0.00'} ج.م',
                                style: AppTextStyles.price.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const Text('استكشاف خامات', style: AppTextStyles.h2),
            const SizedBox(height: 12),
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.style_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'معرض التنسيقات والأفكار (Lookbook)',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        context.push('/style-gallery');
                      },
                    ),
                    const Divider(height: 1, color: AppColors.borderLight),
                    ListTile(
                      leading: const Icon(
                        Icons.design_services_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'طلب تصميم خاص (Custom Order)',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        context.push('/custom-order');
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Developer credits / support
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('إصدار التطبيق', style: AppTextStyles.body),
                        Text(
                          '1.0.0',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppColors.borderLight),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الدعم الفني', style: AppTextStyles.body),
                        Text(
                          'support@5amat-handmade.com',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLoyaltyCard() {
    final int points = _verifiedPoints ?? (_orders.length * 10);
    final bool isVerified = _verifiedPoints != null;

    String tierName = 'الهاوي البرونزي (Bronze)';
    Color tierColor = Colors.brown.shade400;
    IconData tierIcon = Icons.stars_outlined;
    double progress = 0.0;
    String nextTierText = 'متبقي 30 نقطة للوصول للمستوى الفضي';

    if (points >= 60) {
      tierName = 'المصمم الذهبي (Gold)';
      tierColor = Colors.amber.shade700;
      tierIcon = Icons.workspace_premium;
      progress = 1.0;
      nextTierText = 'لقد وصلت للمستوى الذهبي الأعلى! 🎉';
    } else if (points >= 30) {
      tierName = 'المحترف الفضي (Silver)';
      tierColor = Colors.grey.shade600;
      tierIcon = Icons.military_tech;
      progress = (points - 30) / 30;
      nextTierText = 'متبقي ${60 - points} نقطة للوصول للمستوى الذهبي';
    } else {
      progress = points / 30;
      nextTierText = 'متبقي ${30 - points} نقطة للوصول للمستوى الفضي';
    }

    return Card(
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tierColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(tierIcon, color: tierColor, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'مستوى الولاء للهاند ميد',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: AppColors.textMedium,
                            ),
                          ),
                          if (_phone.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: _fetchVerifiedPoints,
                              child: _isLoadingPoints
                                  ? const SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.0,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.primary,
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.refresh,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tierName,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isVerified) ...[
                          const Icon(
                            Icons.verified,
                            color: Colors.blue,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          '$points',
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.primary,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'نقطة مفعّلة',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 10,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(tierColor),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  nextTierText,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    color: AppColors.textMedium,
                  ),
                ),
                Text(
                  isVerified
                      ? 'تم التحقق من المتجر'
                      : '${_orders.length} طلبات',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isVerified ? Colors.blue : AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                value.isNotEmpty ? value : 'غير مسجل',
                style: AppTextStyles.body.copyWith(
                  color: value.isNotEmpty
                      ? AppColors.textDark
                      : AppColors.textLight,
                  fontWeight: value.isNotEmpty
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
