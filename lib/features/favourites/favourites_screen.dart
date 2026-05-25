import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

import '../../shared/providers/favourites_provider.dart';
import '../../shared/providers/api_providers.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/models/product_model.dart';

import 'package:share_plus/share_plus.dart';

// Resolved favorites provider using parallel fetching
final resolvedFavouritesProvider = FutureProvider<List<ProductModel>>((ref) async {
  final favoriteIds = ref.watch(favouritesProvider);
  if (favoriteIds.isEmpty) return [];

  final service = ref.watch(woocommerceServiceProvider);
  return service.getProductsByIds(favoriteIds);
});

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favProductsAsync = ref.watch(resolvedFavouritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المنتجات المفضلة'),
        actions: favProductsAsync.maybeWhen(
          data: (products) {
            if (products.isEmpty) return null;
            return [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'مشاركة المفضلة',
                onPressed: () async {
                  final idsStr = products.map((p) => p.id).join(',');
                  final shareLink = 'https://5amat-handmade.com/wishlist?ids=$idsStr';
                  await Share.share(
                    '🌸 شوفي قائمة المنتجات اللي اخترتها من متجر خامات!\n\n$shareLink',
                    subject: 'مفضّلتي في خامات',
                  );
                },
              ),
            ];
          },
          orElse: () => null,
        ),
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(resolvedFavouritesProvider);
        },
        child: favProductsAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return EmptyStateWidget(
                title: 'قائمتك المفضلة فارغة',
                description: 'اضغط على رمز القلب على أي منتج أثناء تصفحك للمتجر لحفظه هنا والرجوع إليه لاحقاً.',
                icon: Icons.favorite_border_outlined,
                buttonText: 'ابدأ التسوق',
                onButtonPressed: () {
                  context.go('/shop');
                },
              );
            }

            return GridView.builder(
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
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, stack) => EmptyStateWidget(
            title: 'عذراً، حدث خطأ ما',
            description: 'فشل تحميل المنتجات المفضلة. يرجى التحقق من اتصالك بالإنترنت.',
            icon: Icons.error_outline,
            buttonText: 'إعادة المحاولة',
            onButtonPressed: () {
              ref.invalidate(resolvedFavouritesProvider);
            },
          ),
        ),
      ),
    );
  }
}
