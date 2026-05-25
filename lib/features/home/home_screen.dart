import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/providers/app_config_provider.dart';
import '../../shared/providers/api_providers.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/shimmer_loader.dart';
import '../../shared/models/product_model.dart';
import '../../shared/models/category_model.dart';
import '../../shared/widgets/surprise_me_widget.dart';

import '../../shared/widgets/countdown_banner.dart';

// Fetch home products (e.g. limit to 10 newest items)

final homeProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final service = ref.watch(woocommerceServiceProvider);
  return await service.getProducts(page: 1, perPage: 10);
});

// Fetch home categories
final homeCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final service = ref.watch(woocommerceServiceProvider);
  return await service.getCategories();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(appConfigProvider);
    final categoriesAsync = ref.watch(homeCategoriesProvider);
    final productsAsync = ref.watch(homeProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 36,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text('خامات هاند ميد'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(appConfigProvider);
          ref.invalidate(homeCategoriesProvider);
          ref.invalidate(homeProductsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Bar Redirection Widget
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: () {
                    context.go('/shop');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: AppColors.textMedium),
                        SizedBox(width: 12),
                        Text(
                          'ابحث عن قوالب، ريزن، ألوان...',
                          style: TextStyle(color: AppColors.textLight, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Banners Carousel & Countdown
              configAsync.when(
                data: (config) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (config.banners.isNotEmpty) ...[
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 160.0,
                            autoPlay: true,
                            enlargeCenterPage: true,
                            aspectRatio: 16 / 9,
                            autoPlayInterval: const Duration(seconds: 4),
                            viewportFraction: 0.92,
                          ),
                          items: config.banners.map((url) {
                            return Builder(
                              builder: (BuildContext context) {
                                return Container(
                                  width: MediaQuery.of(context).size.width,
                                  margin: const EdgeInsets.symmetric(horizontal: 2.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    image: DecorationImage(
                                      image: NetworkImage(url),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                      ],
                      CountdownBanner(config: config),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: ShimmerLoader(width: double.infinity, height: 160, borderRadius: 16),
                ),
                error: (err, stack) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),
              const SurpriseMeWidget(),
              const SizedBox(height: 16),

              // Categories Section Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('تصفح بالأقسام', style: AppTextStyles.h2),
                    TextButton(
                      onPressed: () => context.go('/shop'),
                      child: const Text('عرض الكل', style: TextStyle(color: AppColors.primaryDark)),
                    ),
                  ],
                ),
              ),

              // Categories Horizontal List
              SizedBox(
                height: 110,
                child: categoriesAsync.when(
                  data: (categories) {
                    if (categories.isEmpty) {
                      return const Center(child: Text('لا توجد أقسام متوفرة حالياً'));
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        return GestureDetector(
                          onTap: () {
                            // Go to shop filtered by this category
                            context.go('/shop?catId=${cat.id}');
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor: AppColors.primaryLight.withOpacity(0.3),
                                  backgroundImage: cat.imageUrl != null ? NetworkImage(cat.imageUrl!) : null,
                                  child: cat.imageUrl == null
                                      ? const Icon(Icons.category, color: AppColors.primary, size: 28)
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    cat.name,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: 5,
                    itemBuilder: (context, index) => ShimmerLoader.categoryItem(),
                  ),
                  error: (err, stack) => const Center(child: Text('عذراً، فشل تحميل الأقسام')),
                ),
              ),

              const SizedBox(height: 16),

              // New Arrivals Section Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text('أحدث الإضافات', style: AppTextStyles.h2),
              ),

              // Products Staggered Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: productsAsync.when(
                  data: (products) {
                    if (products.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(child: Text('لا توجد منتجات متوفرة حالياً')),
                      );
                    }
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
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
                  loading: () => GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) => ShimmerLoader.productCard(),
                  ),
                  error: (err, stack) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(child: Text('عذراً، فشل تحميل المنتجات. تأكد من اتصالك بالإنترنت.')),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
