class ProductModel {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String shortDescription;
  final String permalink;
  final bool onSale;
  final double price;
  final double regularPrice;
  final double salePrice;
  final String currencySymbol;
  final String currencyCode;
  final List<String> images;
  final List<String> categories;
  final bool isInStock;
  final String stockStatus;

  ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.shortDescription,
    required this.permalink,
    required this.onSale,
    required this.price,
    required this.regularPrice,
    required this.salePrice,
    required this.currencySymbol,
    required this.currencyCode,
    required this.images,
    required this.categories,
    required this.isInStock,
    required this.stockStatus,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Parse prices
    final prices = json['prices'] ?? {};
    final minorUnit = prices['currency_minor_unit'] as int? ?? 2;
    final divisor = minorUnit == 2 ? 100.0 : (minorUnit == 0 ? 1.0 : 100.0);

    final rawPrice = double.tryParse(prices['price']?.toString() ?? '0') ?? 0.0;
    final rawRegPrice = double.tryParse(prices['regular_price']?.toString() ?? '0') ?? 0.0;
    final rawSalePrice = double.tryParse(prices['sale_price']?.toString() ?? '0') ?? 0.0;

    final price = rawPrice / divisor;
    final regularPrice = rawRegPrice / divisor;
    final salePrice = rawSalePrice / divisor;

    final currencySymbol = prices['currency_symbol']?.toString() ?? 'ج.م';
    final currencyCode = prices['currency_code']?.toString() ?? 'EGP';

    // Parse images
    final imageList = json['images'] as List? ?? [];
    final images = imageList.map((img) => img['src']?.toString() ?? '').where((src) => src.isNotEmpty).toList();

    // Parse categories
    final catList = json['categories'] as List? ?? [];
    final categories = catList.map((cat) => cat['name']?.toString() ?? '').toList();

    return ProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      shortDescription: json['short_description'] ?? '',
      permalink: json['permalink'] ?? '',
      onSale: json['on_sale'] ?? false,
      price: price,
      regularPrice: regularPrice,
      salePrice: salePrice,
      currencySymbol: currencySymbol,
      currencyCode: currencyCode,
      images: images.isEmpty ? ['https://5amat-handmade.com/wp-content/uploads/2026/03/resin.png'] : images,
      categories: categories,
      isInStock: json['is_in_stock'] ?? true,
      stockStatus: (json['stock_availability']?['class'] ?? 'in-stock').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'short_description': shortDescription,
      'permalink': permalink,
      'on_sale': onSale,
      'prices': {
        'price': (price * 100).toInt().toString(),
        'regular_price': (regularPrice * 100).toInt().toString(),
        'sale_price': (salePrice * 100).toInt().toString(),
        'currency_symbol': currencySymbol,
        'currency_code': currencyCode,
        'currency_minor_unit': 2,
      },
      'images': images.map((src) => {'src': src}).toList(),
      'categories': categories.map((name) => {'name': name}).toList(),
      'is_in_stock': isInStock,
      'stock_availability': {'class': stockStatus},
    };
  }
}
