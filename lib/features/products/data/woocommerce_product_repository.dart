import 'package:dio/dio.dart';

import '../../../core/env/app_env.dart';
import '../../../core/error/result.dart';
import '../domain/product.dart';
import '../domain/product_category.dart';
import '../domain/product_repository.dart';
import '../domain/product_review.dart';

/// WooCommerce REST API (`/wp-json/wc/v3`) implementation.
///
/// nnfoodsandspices.com runs WordPress + WooCommerce, so once the store
/// owner issues a REST API consumer key/secret (WooCommerce → Settings →
/// Advanced → REST API), set them via `--dart-define-from-file=env.json`
/// (see `env.example.json`) and [ProductRepositoryConfig] switches the app
/// over to this class automatically — no UI changes required.
class WooCommerceProductRepository implements ProductRepository {
  WooCommerceProductRepository(this._dio);

  final Dio _dio;

  Map<String, String> get _authParams => {
        'consumer_key': AppEnv.wooCommerceConsumerKey,
        'consumer_secret': AppEnv.wooCommerceConsumerSecret,
      };

  String get _baseUrl => '${AppEnv.wooCommerceBaseUrl}/wp-json/wc/v3';

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.success(await action());
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return Result.failure(AppFailure.network());
      }
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        return Result.failure(AppFailure.unauthorized());
      }
      if (e.response?.statusCode == 404) {
        return Result.failure(AppFailure.notFound());
      }
      return Result.failure(AppFailure.server(e.message));
    } catch (e) {
      return Result.failure(AppFailure.unknown(e.toString()));
    }
  }

  @override
  Future<Result<List<ProductCategory>>> getCategories() {
    return _guard(() async {
      final res = await _dio.get('$_baseUrl/products/categories', queryParameters: _authParams);
      return (res.data as List)
          .map((json) => ProductCategory(
                id: json['id'].toString(),
                name: json['name'] as String,
                slug: json['slug'] as String,
                description: (json['description'] as String?) ?? '',
                imageUrl: (json['image']?['src'] as String?) ?? '',
                productCount: (json['count'] as num?)?.toInt() ?? 0,
              ))
          .toList();
    });
  }

  @override
  Future<Result<List<Product>>> getProducts({
    String? categoryId,
    String? query,
    ProductSortOption sort = ProductSortOption.newest,
    bool? isVeg,
    bool? inStockOnly,
    double? minPrice,
    double? maxPrice,
    int page = 1,
    int pageSize = 20,
  }) {
    return _guard(() async {
      final res = await _dio.get('$_baseUrl/products', queryParameters: {
        ..._authParams,
        'page': page,
        'per_page': pageSize,
        if (categoryId != null) 'category': categoryId,
        if (query != null && query.isNotEmpty) 'search': query,
        if (inStockOnly == true) 'stock_status': 'instock',
        if (minPrice != null) 'min_price': minPrice.toString(),
        if (maxPrice != null) 'max_price': maxPrice.toString(),
        'orderby': _orderByFor(sort),
        'order': sort == ProductSortOption.priceHighToLow ? 'desc' : 'asc',
      });
      return (res.data as List).map(_productFromJson).toList();
    });
  }

  String _orderByFor(ProductSortOption sort) => switch (sort) {
        ProductSortOption.priceLowToHigh || ProductSortOption.priceHighToLow => 'price',
        ProductSortOption.rating => 'rating',
        ProductSortOption.nameAZ => 'title',
        ProductSortOption.newest => 'date',
      };

  Product _productFromJson(dynamic json) {
    final images = (json['images'] as List?)?.map((i) => i['src'] as String).toList() ?? [];
    final regular = double.tryParse(json['regular_price']?.toString() ?? '') ?? 0;
    final sale = double.tryParse(json['sale_price']?.toString() ?? '');
    return Product(
      id: json['id'].toString(),
      name: json['name'] as String,
      slug: json['slug'] as String,
      categoryId: ((json['categories'] as List?)?.firstOrNull?['id'])?.toString() ?? '',
      categoryName: ((json['categories'] as List?)?.firstOrNull?['name']) ?? '',
      description: (json['description'] as String?) ?? '',
      shortDescription: (json['short_description'] as String?) ?? '',
      price: sale ?? regular,
      compareAtPrice: sale != null ? regular : null,
      imageUrl: images.isNotEmpty ? images.first : '',
      galleryImages: images,
      availability:
          json['stock_status'] == 'instock' ? ProductAvailability.inStock : ProductAvailability.outOfStock,
      rating: double.tryParse(json['average_rating']?.toString() ?? '') ?? 0,
      reviewCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      sku: (json['sku'] as String?) ?? json['id'].toString(),
    );
  }

  @override
  Future<Result<Product>> getProductById(String id) {
    return _guard(() async {
      final res = await _dio.get('$_baseUrl/products/$id', queryParameters: _authParams);
      return _productFromJson(res.data);
    });
  }

  @override
  Future<Result<List<Product>>> getFeaturedProducts() {
    return _guard(() async {
      final res = await _dio.get('$_baseUrl/products', queryParameters: {
        ..._authParams,
        'featured': true,
      });
      return (res.data as List).map(_productFromJson).toList();
    });
  }

  @override
  Future<Result<List<Product>>> getLatestProducts() {
    return _guard(() async {
      final res = await _dio.get('$_baseUrl/products', queryParameters: {
        ..._authParams,
        'orderby': 'date',
        'order': 'desc',
        'per_page': 10,
      });
      return (res.data as List).map(_productFromJson).toList();
    });
  }

  @override
  Future<Result<List<Product>>> getRelatedProducts(String productId) {
    return _guard(() async {
      final product = await _dio.get('$_baseUrl/products/$productId', queryParameters: _authParams);
      final relatedIds = (product.data['related_ids'] as List?)?.join(',') ?? '';
      if (relatedIds.isEmpty) return <Product>[];
      final res = await _dio.get('$_baseUrl/products', queryParameters: {
        ..._authParams,
        'include': relatedIds,
      });
      return (res.data as List).map(_productFromJson).toList();
    });
  }

  @override
  Future<Result<List<ProductReview>>> getReviews(String productId) {
    return _guard(() async {
      final res = await _dio.get('$_baseUrl/products/reviews', queryParameters: {
        ..._authParams,
        'product': productId,
      });
      return (res.data as List)
          .map((json) => ProductReview(
                id: json['id'].toString(),
                productId: productId,
                authorName: json['reviewer'] as String,
                rating: (json['rating'] as num).toDouble(),
                comment: (json['review'] as String?) ?? '',
                createdAt: DateTime.parse(json['date_created'] as String),
                verifiedPurchase: json['verified'] as bool? ?? false,
              ))
          .toList();
    });
  }

  @override
  Future<Result<List<String>>> getSearchSuggestions(String query) {
    return _guard(() async {
      final res = await _dio.get('$_baseUrl/products', queryParameters: {
        ..._authParams,
        'search': query,
        'per_page': 6,
      });
      return (res.data as List).map((j) => j['name'] as String).toList();
    });
  }
}
