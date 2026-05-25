import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/providers/api_providers.dart';
import '../../shared/providers/favourites_provider.dart';
import '../cart/cart_provider.dart';
import '../../shared/models/product_model.dart';
import '../../shared/models/cart_item_model.dart';
import '../../core/analytics/app_analytics.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  ProductModel? _product;
  bool _isLoading = true;
  bool _hasError = false;
  int _quantity = 1;
  int _currentImageIndex = 0;
  bool _isSubmittingAlert = false;

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final service = ref.read(woocommerceServiceProvider);
      final details = await service.getProductById(widget.productId);
      setState(() {
        _product = details;
        _isLoading = false;
      });
      // Log Firebase Analytics Event
      if (details != null) {
        AppAnalytics.logProductView(details);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  // Decoupled, robust utility to strip HTML markup for clean native presentation
  String _stripHtml(String htmlString) {
    if (htmlString.isEmpty) return '';
    
    // Replace paragraph endings with double newlines
    String result = htmlString.replaceAll(RegExp(r'</p>'), '\n\n');
    // Replace breaklines with newline
    result = result.replaceAll(RegExp(r'<br\s*/?>'), '\n');
    // Strip all other HTML tags
    result = result.replaceAll(RegExp(r'<[^>]*>'), '');
    // Decode HTML entities (e.g. &nbsp;, &amp;)
    result = result.replaceAll('&nbsp;', ' ');
    result = result.replaceAll('&amp;', '&');
    result = result.replaceAll('&quot;', '"');
    result = result.replaceAll('&#39;', "'");
    
    return result.trim();
  }

  Future<void> _handleSubscribeToStockAlert() async {
    if (_product == null) return;
    setState(() {
      _isSubmittingAlert = true;
    });

    try {
      final service = ref.read(woocommerceServiceProvider);
      final success = await service.subscribeToStockAlert(_product!.id);

      if (mounted) {
        if (success) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                '🔔 تم تفعيل التنبيه',
                style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
              content: const Text(
                'سنقوم بإرسال إشعار فوري لكِ على هذا الجهاز بمجرد توفر المنتج في المخزن مجدداً!',
                style: TextStyle(fontFamily: 'Tajawal'),
                textAlign: TextAlign.right,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'حسناً',
                    style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          );
        } else {
          throw Exception('failed');
        }
      }
    } catch (e) {
      if (mounted) {
        final isNotificationDisabled = e.toString().contains('notifications_disabled');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              '⚠️ تفعيل التنبيهات مطلوب',
              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
            content: Text(
              isNotificationDisabled
                  ? 'يرجى تفعيل إشعارات التطبيق أولاً لتتمكن من تلقي تنبيهات توفر المنتجات.'
                  : 'عذراً، حدث خطأ أثناء تفعيل التنبيه. يرجى المحاولة مرة أخرى لاحقاً.',
              style: const TextStyle(fontFamily: 'Tajawal'),
              textAlign: TextAlign.right,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'حسناً',
                  style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingAlert = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final favourites = ref.watch(favouritesProvider);
    final isFav = _product != null && favourites.contains(_product!.id);

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_hasError || _product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل المنتج')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.alert),
              const SizedBox(height: 16),
              const Text('فشل في تحميل تفاصيل المنتج', style: AppTextStyles.h2),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchProductDetails,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    final product = _product!;
    final discount = product.regularPrice > product.price
        ? (((product.regularPrice - product.price) / product.regularPrice) * 100).round()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              Share.share('تفقد هذا المنتج الرائع على متجر خامات: ${product.name}\n${product.permalink}');
            },
          ),
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? AppColors.alert : AppColors.textDark,
            ),
            onPressed: () {
              final wasFav = ref.read(favouritesProvider).contains(product.id);
              ref.read(favouritesProvider.notifier).toggleFavourite(product.id);
              if (wasFav) {
                AppAnalytics.logRemoveFromWishlist(product);
              } else {
                AppAnalytics.logAddToWishlist(product);
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Scrollable details content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image Gallery Carousel
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 300,
                          viewportFraction: 1.0,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                        ),
                        items: product.images.map((url) {
                          return CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => Container(
                              color: AppColors.borderLight,
                              child: const Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.borderLight,
                              child: const Icon(Icons.image, size: 64, color: AppColors.textLight),
                            ),
                          );
                        }).toList(),
                      ),
                      // Dot indicators for gallery
                      if (product.images.length > 1)
                        Positioned(
                          bottom: 12,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              product.images.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: _currentImageIndex == index ? 12 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == index ? AppColors.primary : Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Categories List
                        if (product.categories.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            children: product.categories.map((cat) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  cat,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 12),

                        // Title
                        Text(product.name, style: AppTextStyles.h1),

                        const SizedBox(height: 12),

                        // Price and Discount row
                        Row(
                          children: [
                            Text(
                              '${product.price.toStringAsFixed(2)} ${product.currencySymbol}',
                              style: AppTextStyles.price.copyWith(fontSize: 22),
                            ),
                            const SizedBox(width: 12),
                            if (product.onSale) ...[
                              Text(
                                '${product.regularPrice.toStringAsFixed(2)} ${product.currencySymbol}',
                                style: AppTextStyles.priceOld.copyWith(fontSize: 16),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.alert,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'خصم $discount%',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Stock Availability
                        Row(
                          children: [
                            Icon(
                              product.isInStock ? Icons.check_circle_outline : Icons.highlight_off,
                              color: product.isInStock ? AppColors.secondary : AppColors.alert,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              product.isInStock ? 'متوفر في المخزن' : 'غير متوفر حالياً',
                              style: AppTextStyles.body.copyWith(
                                color: product.isInStock ? AppColors.secondary : AppColors.alert,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 32, color: AppColors.border),

                        // Description
                        const Text('وصف المنتج', style: AppTextStyles.h2),
                        const SizedBox(height: 12),
                        Text(
                          _stripHtml(product.description.isNotEmpty ? product.description : product.shortDescription),
                          style: AppTextStyles.body.copyWith(height: 1.6),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom CTA Actions (Buy panel)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Quantity Incrementer
                  if (product.isInStock) ...[
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: () {
                              if (_quantity > 1) {
                                setState(() {
                                  _quantity--;
                                });
                              }
                            },
                          ),
                          Text(
                            '$_quantity',
                            style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () {
                              setState(() {
                                _quantity++;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],

                  // Add To Cart Button / Disable Button
                  Expanded(
                    child: product.isInStock
                        ? ElevatedButton(
                            onPressed: () {
                              ref.read(cartProvider.notifier).addItem(
                                    CartItemModel(
                                      id: product.id,
                                      name: product.name,
                                      price: product.price,
                                      quantity: _quantity,
                                      imageUrl: product.images.first,
                                    ),
                                  );
                              AppAnalytics.logAddToCart(product, _quantity);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('تمت إضافة $_quantity × ${product.name} إلى السلة!'),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_shopping_cart, size: 20),
                                SizedBox(width: 8),
                                Text('إضافة إلى السلة'),
                              ],
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _isSubmittingAlert ? null : _handleSubscribeToStockAlert,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 2,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isSubmittingAlert)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                else ...[
                                  const Icon(Icons.notifications_active_outlined, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('أبلغني عند توفر المنتج'),
                                ],
                              ],
                            ),
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
