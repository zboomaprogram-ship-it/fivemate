import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/empty_state_widget.dart';
import 'cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    final appliedPromo = ref.watch(appliedPromoProvider);
    final discount = ref.watch(promoDiscountProvider);
    final subtotal = cartNotifier.totalPrice;
    final discountAmount = subtotal * discount;
    final total = subtotal - discountAmount;

    if (cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('سلة التسوق')),
        body: EmptyStateWidget(
          title: 'سلتك فارغة حالياً',
          description:
              'تصفحي المتجر وأضيفي أفضل قوالب السيليكون وخامات الهاند ميد المفضلة لديكِ.',
          icon: Icons.shopping_basket_outlined,
          buttonText: 'تصفح المتجر',
          onButtonPressed: () {
            // Jump to the shop tab branch
            context.go('/shop');
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('سلة التسوق'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_sweep_outlined,
              color: AppColors.alert,
            ),
            onPressed: () => _showClearCartDialog(context, cartNotifier),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // List of items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Dismissible(
                  key: ValueKey('${item.id}_${item.variation ?? ''}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.only(left: 20),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: AppColors.alert,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  onDismissed: (_) {
                    cartNotifier.removeItem(item.id, item.variation);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تمت إزالة ${item.name} من السلة'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          // Item Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: item.imageUrl,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.borderLight,
                                child: const Icon(
                                  Icons.image,
                                  size: 32,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Title & price details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (item.variation != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.variation!,
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  '${item.price.toStringAsFixed(2)} ج.م',
                                  style: AppTextStyles.price.copyWith(
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Quantity changer controls
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.textLight,
                                  size: 20,
                                ),
                                onPressed: () {
                                  cartNotifier.removeItem(
                                    item.id,
                                    item.variation,
                                  );
                                },
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      cartNotifier.updateQuantity(
                                        item.id,
                                        item.variation,
                                        item.quantity - 1,
                                      );
                                    },
                                    child: const CircleAvatar(
                                      radius: 12,
                                      backgroundColor: AppColors.border,
                                      child: Icon(
                                        Icons.remove,
                                        size: 14,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      cartNotifier.updateQuantity(
                                        item.id,
                                        item.variation,
                                        item.quantity + 1,
                                      );
                                    },
                                    child: const CircleAvatar(
                                      radius: 12,
                                      backgroundColor: AppColors.primary,
                                      child: Icon(
                                        Icons.add,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Promotion Code Section
          _PromoCodeSection(ref: ref),

          // Total Panel
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (discount > 0.0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'المجموع الفرعي',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            color: AppColors.textMedium,
                          ),
                        ),
                        Text(
                          '${subtotal.toStringAsFixed(2)} ج.م',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textMedium,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'خصم الكوبون ($appliedPromo)',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '-${discountAmount.toStringAsFixed(2)} ج.م',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'المجموع الكلي',
                        style: AppTextStyles.titleMedium,
                      ),
                      Text(
                        '${total.toStringAsFixed(2)} ج.م',
                        style: AppTextStyles.price.copyWith(fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '* مصاريف التوصيل تُحدد من قبل المندوب عند التوصيل',
                    style: TextStyle(color: AppColors.textMedium, fontSize: 11),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      context.push('/cart/checkout');
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment, size: 20),
                        SizedBox(width: 8),
                        Text('متابعة إتمام الطلب'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoCodeSection extends StatefulWidget {
  final WidgetRef ref;
  const _PromoCodeSection({required this.ref});

  @override
  State<_PromoCodeSection> createState() => _PromoCodeSectionState();
}

class _PromoCodeSectionState extends State<_PromoCodeSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyCode() {
    final code = _controller.text.trim().toUpperCase();
    if (code.isEmpty) return;

    double discount = 0.0;
    if (code == '5AMAT10') {
      discount = 0.10;
    } else if (code == 'WELCOME5') {
      discount = 0.05;
    } else if (code == 'HANDMADE15') {
      discount = 0.15;
    }

    if (discount > 0.0) {
      widget.ref.read(appliedPromoProvider.notifier).state = code;
      widget.ref.read(promoDiscountProvider.notifier).state = discount;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تطبيق الكود $code بنجاح! خصم ${(discount * 100).toInt()}%',
          ),
          backgroundColor: AppColors.secondary,
        ),
      );
      _controller.clear();
      FocusScope.of(context).unfocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('كود الخصم غير صالح، يرجى المحاولة مرة أخرى'),
          backgroundColor: AppColors.alert,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appliedPromo = widget.ref.watch(appliedPromoProvider);
    final discount = widget.ref.watch(promoDiscountProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border.withOpacity(0.5)),
          bottom: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'هل لديك كود خصم؟',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              fontFamily: 'Tajawal',
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          if (appliedPromo == null)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 45,
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'أدخلي كود الخصم (مثال: 5AMAT10)',
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Tajawal',
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 45,
                  child: ElevatedButton(
                    onPressed: _applyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(0, 45),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text(
                      'تطبيق',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'كود الخصم نشط: $appliedPromo (${(discount * 100).toInt()}% خصم)',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      widget.ref.read(appliedPromoProvider.notifier).state =
                          null;
                      widget.ref.read(promoDiscountProvider.notifier).state =
                          0.0;
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

void _showClearCartDialog(BuildContext context, CartNotifier cartNotifier) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('تفريغ السلة؟', textAlign: TextAlign.right),
      content: const Text(
        'هل أنت متأكد من رغبتك في إزالة جميع المنتجات من السلة؟',
        textAlign: TextAlign.right,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () {
            cartNotifier.clearCart();
            Navigator.pop(context);
          },
          child: const Text(
            'نعم، تفريغ السلة',
            style: TextStyle(color: AppColors.alert),
          ),
        ),
      ],
    ),
  );
}
