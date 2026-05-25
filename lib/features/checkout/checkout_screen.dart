import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/providers/app_config_provider.dart';
import '../../shared/models/app_config_model.dart';
import '../cart/cart_provider.dart';
import '../../core/analytics/app_analytics.dart';
import '../../shared/models/cart_item_model.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _giftMessageController = TextEditingController();
  
  String? _selectedGovernorate;
  bool _isGift = false;
  late final Box _prefsBox;
  late final Box _ordersBox;

  // Premium list of Egypt governorates
  final List<String> _governorates = [
    'القاهرة',
    'الجيزة',
    'الدقهلية (المنصورة)',
    'الإسكندرية',
    'القليوبية',
    'الشرقية',
    'الغربية',
    'المنوفية',
    'البحيرة',
    'كفر الشيخ',
    'دمياط',
    'بورسعيد',
    'الإسماعيلية',
    'السويس',
    'الفيوم',
    'بني سويف',
    'المنيا',
    'أسيوط',
    'سوهاج',
    'قنا',
    'الأقصر',
    'أسوان',
    'البحر الأحمر',
    'مطروح',
    'الوادي الجديد',
    'شمال سيناء',
    'جنوب سيناء',
  ];

  String get _deliveryEstimate {
    if (_selectedGovernorate == null) return '';
    final gov = _selectedGovernorate!;
    if (gov == 'القاهرة' || gov == 'الجيزة') {
      return 'خلال 24 إلى 48 ساعة عمل';
    } else if ([
      'الإسكندرية',
      'الدقهلية (المنصورة)',
      'القليوبية',
      'الشرقية',
      'الغربية',
      'المنوفية',
      'البحيرة',
      'كفر الشيخ',
      'دمياط',
      'بورسعيد',
      'الإسماعيلية',
      'السويس'
    ].contains(gov)) {
      return 'خلال 2 إلى 3 أيام عمل';
    } else {
      return 'خلال 3 إلى 5 أيام عمل';
    }
  }

  @override
  void initState() {
    super.initState();
    _prefsBox = Hive.box('prefs_box');
    _ordersBox = Hive.box('orders_box');
    _loadSavedDetails();

    // Log Begin Checkout Event
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartItems = ref.read(cartProvider);
      final subtotal = ref.read(cartProvider.notifier).totalPrice;
      AppAnalytics.logBeginCheckout(cartItems, subtotal);
    });
  }

  void _loadSavedDetails() {
    _nameController.text = _prefsBox.get('client_name', defaultValue: '');
    _phoneController.text = _prefsBox.get('client_phone', defaultValue: '');
    _addressController.text = _prefsBox.get('client_address', defaultValue: '');
    final savedGov = _prefsBox.get('client_governorate');
    if (savedGov != null && _governorates.contains(savedGov)) {
      _selectedGovernorate = savedGov;
    }
  }

  void _saveDetails() {
    _prefsBox.put('client_name', _nameController.text.trim());
    _prefsBox.put('client_phone', _phoneController.text.trim());
    _prefsBox.put('client_address', _addressController.text.trim());
    if (_selectedGovernorate != null) {
      _prefsBox.put('client_governorate', _selectedGovernorate);
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate() || _selectedGovernorate == null) {
      if (_selectedGovernorate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء اختيار المحافظة'),
            backgroundColor: AppColors.alert,
          ),
        );
      }
      return;
    }

    _saveDetails();

    final cartItems = ref.read(cartProvider);
    final subtotal = ref.read(cartProvider.notifier).totalPrice;
    
    // Read applied coupon details
    final appliedPromo = ref.read(appliedPromoProvider);
    final promoDiscount = ref.read(promoDiscountProvider);
    final discountAmount = subtotal * promoDiscount;
    final total = subtotal - discountAmount;
    
    // Read shop config values (number and template)
    final configAsync = ref.read(appConfigProvider);
    final config = configAsync.value ?? AppConfigModel.localFallback;

    // Compile line items text
    final StringBuffer itemsBuffer = StringBuffer();
    for (var item in cartItems) {
      itemsBuffer.writeln('• ${item.quantity} × ${item.name} (${(item.price * item.quantity).toStringAsFixed(2)} ج.م)');
    }

    // Format final template message
    String message = config.whatsappTextTemplate;
    message = message.replaceAll('{name}', _nameController.text.trim());
    message = message.replaceAll('{phone}', _phoneController.text.trim());
    message = message.replaceAll('{governorate}', _selectedGovernorate!);
    message = message.replaceAll('{address}', _addressController.text.trim());
    message = message.replaceAll('{items}', itemsBuffer.toString().trim());
    message = message.replaceAll('{total}', total.toStringAsFixed(2));

    // Append coupon code details if active
    if (appliedPromo != null && promoDiscount > 0.0) {
      message += '\n\n🏷️ *كود الخصم المستخدم*: $appliedPromo';
      message += '\n💰 *قيمة الخصم*: -${discountAmount.toStringAsFixed(2)} ج.م (${(promoDiscount * 100).toInt()}%)';
    }

    // Append to message if gift
    if (_isGift) {
      message += '\n\n🎁 *طلب مغلف كهدية*';
      message += '\n💬 *رسالة الإهداء*: "${_giftMessageController.text.trim()}"';
    }

    // Append delivery estimation
    message += '\n\n⏰ *وقت التوصيل المتوقع*: $_deliveryEstimate';

    // Save order details to local orders history log
    final newOrder = {
      'date': DateTime.now().toIso8601String(),
      'total': total,
      'items_count': ref.read(cartProvider.notifier).totalItemsCount,
      'items_summary': cartItems.map((e) => '${e.quantity}× ${e.name}').join(', '),
      'is_gift': _isGift,
      'gift_message': _isGift ? _giftMessageController.text.trim() : '',
      'governorate': _selectedGovernorate!,
      'promo_code': appliedPromo ?? '',
      'discount': discountAmount,
      'message': message,
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
    };
    final List<dynamic> currentOrders = _ordersBox.get('history', defaultValue: []);
    currentOrders.add(newOrder);
    await _ordersBox.put('history', currentOrders);

    // Log E-commerce Purchase Event
    AppAnalytics.logPurchase(
      items: cartItems,
      total: total,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    // Formulate and trigger WhatsApp URI launcher
    final whatsappNumber = config.whatsappNumber;
    final whatsappUrl = Uri.parse('https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        // Fallback launch
        await launchUrl(whatsappUrl, mode: LaunchMode.platformDefault);
      }

      // Clear Shopping Cart and Reset coupons on successful submit redirection
      ref.read(cartProvider.notifier).clearCart();
      ref.read(appliedPromoProvider.notifier).state = null;
      ref.read(promoDiscountProvider.notifier).state = 0.0;

      if (mounted) {
        // Return to home page
        context.go('/home');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت صياغة الفاتورة وإرسالها لواتساب المتجر بنجاح!'),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('عذراً، فشل فتح تطبيق واتساب: $e'),
            backgroundColor: AppColors.alert,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _giftMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartItemsCount = ref.watch(cartProvider.select((c) => ref.read(cartProvider.notifier).totalItemsCount));
    final totalPrice = ref.watch(cartProvider.select((c) => ref.read(cartProvider.notifier).totalPrice));

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل التوصيل')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cart brief recap header card
                Card(
                  color: AppColors.primaryLight.withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ملخص الطلب', style: AppTextStyles.titleMedium),
                            const SizedBox(height: 4),
                            Text('عدد المنتجات: $cartItemsCount', style: AppTextStyles.bodySmall),
                          ],
                        ),
                        Text(
                          '${totalPrice.toStringAsFixed(2)} ج.م',
                          style: AppTextStyles.price.copyWith(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text('بيانات المشتري', style: AppTextStyles.h2),
                const SizedBox(height: 16),

                // Name field
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل *',
                    hintText: 'أدخل اسمك ثلاثي للتوصيل',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال الاسم';
                    }
                    if (value.trim().split(' ').length < 2) {
                      return 'الرجاء إدخال الاسم ثنائياً على الأقل';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Phone number
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف (واتساب) *',
                    hintText: 'مثال: 01012345678',
                    prefixIcon: Icon(Icons.phone_iphone_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال رقم الهاتف';
                    }
                    final cleanVal = value.trim();
                    if (cleanVal.length < 10 || cleanVal.length > 15) {
                      return 'رقم الهاتف غير صالح';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Governorate dropdown
                DropdownButtonFormField<String>(
                  value: _selectedGovernorate,
                  decoration: const InputDecoration(
                    labelText: 'المحافظة *',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  items: _governorates.map((gov) {
                    return DropdownMenuItem<String>(
                      value: gov,
                      child: Text(gov),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGovernorate = value;
                    });
                  },
                  validator: (value) => value == null ? 'الرجاء اختيار المحافظة' : null,
                ),

                if (_selectedGovernorate != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined, color: AppColors.secondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'مدة التوصيل المتوقعة لـ $_selectedGovernorate: $_deliveryEstimate',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Address description
                TextFormField(
                  controller: _addressController,
                  keyboardType: TextInputType.streetAddress,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'العنوان بالتفصيل *',
                    hintText: 'المدينة، اسم الشارع، رقم المبنى، الطابق، علامة مميزة',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال تفاصيل العنوان بالتفصيل';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _isGift ? AppColors.accent : AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                    color: _isGift ? AppColors.accent.withOpacity(0.05) : Colors.transparent,
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('🎁 إرسال كهدية مغلفة؟', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                        subtitle: const Text('تغليف هدايا فاخر يدوي مع كارت إهداء خاص مدمج.', style: TextStyle(fontSize: 12, fontFamily: 'Tajawal')),
                        activeColor: AppColors.accent,
                        value: _isGift,
                        onChanged: (value) {
                          setState(() {
                            _isGift = value;
                          });
                        },
                      ),
                      if (_isGift)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                          child: TextFormField(
                            controller: _giftMessageController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'رسالة كارت الإهداء',
                              hintText: 'اكتب الكلمات التي تود كتابتها على كارت الهدية هنا...',
                              prefixIcon: Icon(Icons.card_giftcard),
                            ),
                            validator: (value) {
                              if (_isGift && (value == null || value.trim().isEmpty)) {
                                return 'الرجاء إدخال رسالة الإهداء';
                              }
                              return null;
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Payment Information Section
                const Text('معلومات الدفع', style: AppTextStyles.h2),
                const SizedBox(height: 16),

                // Warning Box: Price does not include shipping
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9E6),
                    border: Border.all(color: const Color(0xFFFFE599)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFB27A00)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'السعر لا يشمل مصاريف الشحن',
                          style: TextStyle(
                            color: Color(0xFFB27A00),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Payment Method Subtitle
                const Text(
                  'الدفع عبر فودافون كاش',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),

                // Instruction Box with Vodafone Cash number
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5), // Light grey
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'من فضلك بعد إتمام الطلب، قم بتحويل المبلغ على رقم فودافون كاش ثم أرسل صورة أو لقطة شاشة من عملية التحويل على واتساب',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 13,
                          height: 1.5,
                          fontFamily: 'Tajawal',
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          '01092970736',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Privacy Disclaimer
                const Text(
                  'سيتم استخدام بياناتك الشخصية لمعالجة طلبك، ودعم تجربتك في هذا الموقع، ولأغراض أخرى تم توضيحها في سياسة الخصوصية لدينا.',
                  style: TextStyle(
                    color: AppColors.textMedium,
                    fontSize: 11,
                    height: 1.5,
                    fontFamily: 'Tajawal',
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Checkout button (Lavender round button)
                ElevatedButton(
                  onPressed: _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'تأكيد الطلب',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'عند الضغط على تأكيد، سيتم فتح الواتساب تلقائياً لإرسال رسالة تفاصيل الطلب مع الفاتورة. تأكد من تفعيل رقم الواتساب الخاص بك.',
                  style: TextStyle(color: AppColors.textMedium, fontSize: 11, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
