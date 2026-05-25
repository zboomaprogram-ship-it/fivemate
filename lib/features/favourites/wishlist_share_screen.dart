import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/providers/api_providers.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/models/product_model.dart';

final sharedWishlistProvider = FutureProvider.family<List<ProductModel>, String>((ref, idsStr) async {
  if (idsStr.isEmpty) return [];
  final ids = idsStr
      .split(',')
      .map((e) => int.tryParse(e.trim()))
      .whereType<int>()
      .toList();
  
  if (ids.isEmpty) return [];

  final service = ref.watch(woocommerceServiceProvider);
  return service.getProductsByIds(ids);
});

class WishlistShareScreen extends ConsumerWidget {
  final String idsStr;

  const WishlistShareScreen({
    super.key,
    required this.idsStr,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(sharedWishlistProvider(idsStr));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'قائمة المنتجات المشاركة',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(sharedWishlistProvider(idsStr));
          },
          child: productsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return EmptyStateWidget(
                  title: 'لا توجد منتجات',
                  description: 'الرابط المشارك لا يحتوي على أي منتجات صالحة حالياً.',
                  icon: Icons.favorite_border_outlined,
                  buttonText: 'تصفح المتجر',
                  onButtonPressed: () {
                    Navigator.pop(context);
                  },
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                    child: Text(
                      'تمت مشاركة هذه القائمة معكِ (${products.length} منتجات):',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: products.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (context, index) {
                        return ProductCard(product: products[index]);
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (err, stack) => EmptyStateWidget(
              title: 'عذراً، حدث خطأ ما',
              description: 'فشل تحميل المنتجات المشاركة. يرجى التحقق من اتصالك بالإنترنت.',
              icon: Icons.error_outline,
              buttonText: 'إعادة المحاولة',
              onButtonPressed: () {
                ref.invalidate(sharedWishlistProvider(idsStr));
              },
            ),
          ),
        ),
      ),
    );
  }
}
