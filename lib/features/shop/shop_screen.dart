import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/providers/api_providers.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/shimmer_loader.dart';
import '../../shared/models/product_model.dart';
import '../../shared/models/category_model.dart';
import '../../core/analytics/app_analytics.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  bool _isLoadingProducts = false;
  bool _isLoadingCategories = false;
  bool _hasError = false;

  // Filter & Query States
  int? _selectedCategoryId;
  String _searchQuery = '';
  String _orderBy = 'date'; // 'date' or 'price'
  String _order = 'desc'; // 'asc' or 'desc'
  int _currentPage = 1;
  bool _hasMore = true;

  Timer? _searchAnalyticsTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _parseQueryParams();
      _fetchCategories();
      _fetchProducts(refresh: true);
    });
  }

  void _parseQueryParams() {
    final state = GoRouterState.of(context);
    final catIdStr = state.uri.queryParameters['catId'];
    if (catIdStr != null) {
      _selectedCategoryId = int.tryParse(catIdStr);
    }
  }

  // Handle updates when query parameter changes (e.g. tapping categories on Home)
  @override
  void didUpdateWidget(covariant ShopScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final state = GoRouterState.of(context);
    final catIdStr = state.uri.queryParameters['catId'];
    final newCatId = catIdStr != null ? int.tryParse(catIdStr) : null;
    if (newCatId != _selectedCategoryId) {
      setState(() {
        _selectedCategoryId = newCatId;
      });
      _fetchProducts(refresh: true);
    }
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });
    try {
      final service = ref.read(woocommerceServiceProvider);
      final list = await service.getCategories();
      setState(() {
        _categories = list;
        _isLoadingCategories = false;
      });
    } catch (_) {
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _fetchProducts({bool refresh = false}) async {
    if (_isLoadingProducts) return;

    setState(() {
      _isLoadingProducts = true;
      _hasError = false;
      if (refresh) {
        _currentPage = 1;
        _hasMore = true;
        _products = [];
      }
    });

    try {
      final service = ref.read(woocommerceServiceProvider);
      final fetched = await service.getProducts(
        page: _currentPage,
        perPage: 10,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        categoryId: _selectedCategoryId,
        orderBy: _orderBy,
        order: _order,
      );

      setState(() {
        if (fetched.length < 10) {
          _hasMore = false;
        }
        _products.addAll(fetched);
        _currentPage++;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
        _hasError = true;
      });
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _fetchProducts(refresh: true);

    // Debounce analytics search event to avoid spamming on every keystroke
    _searchAnalyticsTimer?.cancel();
    if (query.trim().isNotEmpty) {
      _searchAnalyticsTimer = Timer(const Duration(seconds: 1), () {
        AppAnalytics.logSearch(query.trim());
      });
    }
  }

  void _onCategorySelected(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _fetchProducts(refresh: true);
  }

  void _onSortChanged(String orderBy, String order) {
    setState(() {
      _orderBy = orderBy;
      _order = order;
    });
    _fetchProducts(refresh: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchAnalyticsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('متجر خامات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showSortBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'ابحث عن منتجات...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textMedium),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textMedium),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Categories horizontal filters
          SizedBox(
            height: 48,
            child: _isLoadingCategories && _categories.isEmpty
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 4,
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: ShimmerLoader(width: 80, height: 32, borderRadius: 16),
                    ),
                  )
                : ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // "All" chip
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: const Text('الكل'),
                          selected: _selectedCategoryId == null,
                          onSelected: (_) => _onCategorySelected(null),
                          selectedColor: AppColors.primaryLight,
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(
                            color: _selectedCategoryId == null ? AppColors.primaryDark : AppColors.textMedium,
                            fontWeight: _selectedCategoryId == null ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      // Real categories chips
                      ..._categories.map((cat) {
                        final isSelected = _selectedCategoryId == cat.id;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Text(cat.name),
                            selected: isSelected,
                            onSelected: (_) => _onCategorySelected(cat.id),
                            selectedColor: AppColors.primaryLight,
                            backgroundColor: AppColors.surface,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primaryDark : AppColors.textMedium,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: const BorderSide(color: AppColors.border),
                          ),
                        );
                      }),
                    ],
                  ),
          ),

          const SizedBox(height: 12),

          // Product List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchProducts(refresh: true),
              child: _products.isEmpty
                  ? (_isLoadingProducts
                      ? _buildShimmerGrid()
                      : (_hasError
                          ? _buildErrorWidget()
                          : _buildEmptyWidget()))
                  : CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => ProductCard(product: _products[index]),
                              childCount: _products.length,
                            ),
                          ),
                        ),
                        if (_hasMore)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                              child: _buildLoadMoreWidget(),
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

  Widget _buildEmptyWidget() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.textLight),
            const SizedBox(height: 16),
            const Text('لم نجد أي منتجات تطابق بحثك', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            const Text('جرّب كلمات بحث أخرى أو تصفح الأقسام البديلة.', style: AppTextStyles.body),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                _onSearch('');
                _onCategorySelected(null);
              },
              child: const Text('إعادة ضبط الفلاتر'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: AppColors.alert),
            const SizedBox(height: 16),
            const Text('فشل الاتصال بالخادم', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            const Text('يرجى التحقق من اتصال الإنترنت وإعادة المحاولة.', style: AppTextStyles.body),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _fetchProducts(refresh: true),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreWidget() {
    return Container(
      alignment: Alignment.center,
      child: _isLoadingProducts
          ? const CircularProgressIndicator(color: AppColors.primary)
          : ElevatedButton(
              onPressed: () => _fetchProducts(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight.withOpacity(0.5),
                foregroundColor: AppColors.primaryDark,
                elevation: 0,
                minimumSize: const Size(120, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('تحميل المزيد'),
            ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) => ShimmerLoader.productCard(),
    );
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ترتيب المنتجات حسب',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('الأحدث أولاً'),
                trailing: _orderBy == 'date' ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  _onSortChanged('date', 'desc');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('السعر: من الأقل للأعلى'),
                trailing: _orderBy == 'price' && _order == 'asc' ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  _onSortChanged('price', 'asc');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('السعر: من الأعلى للأقل'),
                trailing: _orderBy == 'price' && _order == 'desc' ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  _onSortChanged('price', 'desc');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
