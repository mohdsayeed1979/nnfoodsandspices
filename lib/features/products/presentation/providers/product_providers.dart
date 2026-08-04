import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/env/app_env.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/local_product_repository.dart';
import '../../data/woocommerce_product_repository.dart';
import '../../domain/product.dart';
import '../../domain/product_category.dart';
import '../../domain/product_repository.dart';
import '../../domain/product_review.dart';

/// Selects the live WooCommerce API when credentials are configured
/// (`--dart-define-from-file=env.json`), otherwise falls back to the local
/// seed catalog. The rest of the app depends only on [ProductRepository].
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  if (AppEnv.hasWooCommerceApi) {
    return WooCommerceProductRepository(DioClient.instance);
  }
  return LocalProductRepository();
});

final categoriesProvider = FutureProvider<List<ProductCategory>>((ref) async {
  final result = await ref.watch(productRepositoryProvider).getCategories();
  return result.when(success: (data) => data, failure: (f) => throw f);
});

final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final result = await ref.watch(productRepositoryProvider).getFeaturedProducts();
  return result.when(success: (data) => data, failure: (f) => throw f);
});

final latestProductsProvider = FutureProvider<List<Product>>((ref) async {
  final result = await ref.watch(productRepositoryProvider).getLatestProducts();
  return result.when(success: (data) => data, failure: (f) => throw f);
});

final productByIdProvider = FutureProvider.family<Product, String>((ref, id) async {
  final result = await ref.watch(productRepositoryProvider).getProductById(id);
  return result.when(success: (data) => data, failure: (f) => throw f);
});

final relatedProductsProvider = FutureProvider.family<List<Product>, String>((ref, id) async {
  final result = await ref.watch(productRepositoryProvider).getRelatedProducts(id);
  return result.when(success: (data) => data, failure: (f) => throw f);
});

final reviewsProvider = FutureProvider.family<List<ProductReview>, String>((ref, id) async {
  final result = await ref.watch(productRepositoryProvider).getReviews(id);
  return result.when(success: (data) => data, failure: (f) => throw f);
});

class ProductQuery {
  const ProductQuery({
    this.categoryId,
    this.query,
    this.sort = ProductSortOption.newest,
    this.isVeg,
    this.inStockOnly,
    this.minPrice,
    this.maxPrice,
  });

  final String? categoryId;
  final String? query;
  final ProductSortOption sort;
  final bool? isVeg;
  final bool? inStockOnly;
  final double? minPrice;
  final double? maxPrice;

  ProductQuery copyWith({
    String? categoryId,
    String? query,
    ProductSortOption? sort,
    bool? isVeg,
    bool? inStockOnly,
    double? minPrice,
    double? maxPrice,
    bool clearCategory = false,
    bool clearVeg = false,
    bool clearPriceRange = false,
  }) {
    return ProductQuery(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      query: query ?? this.query,
      sort: sort ?? this.sort,
      isVeg: clearVeg ? null : (isVeg ?? this.isVeg),
      inStockOnly: inStockOnly ?? this.inStockOnly,
      minPrice: clearPriceRange ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPriceRange ? null : (maxPrice ?? this.maxPrice),
    );
  }
}

class ProductListNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  ProductListNotifier(this._repository, this._query) : super(const AsyncValue.loading()) {
    load();
  }

  final ProductRepository _repository;
  ProductQuery _query;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  ProductQuery get query => _query;
  bool get hasMore => _hasMore;

  Future<void> load() async {
    state = const AsyncValue.loading();
    _page = 1;
    _hasMore = true;
    final result = await _repository.getProducts(
      categoryId: _query.categoryId,
      query: _query.query,
      sort: _query.sort,
      isVeg: _query.isVeg,
      inStockOnly: _query.inStockOnly,
      minPrice: _query.minPrice,
      maxPrice: _query.maxPrice,
      page: _page,
    );
    state = result.when(
      success: (data) {
        _hasMore = data.length >= 20;
        return AsyncValue.data(data);
      },
      failure: (f) => AsyncValue.error(f, StackTrace.current),
    );
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    final current = state.valueOrNull;
    if (current == null) return;
    _isLoadingMore = true;
    final result = await _repository.getProducts(
      categoryId: _query.categoryId,
      query: _query.query,
      sort: _query.sort,
      isVeg: _query.isVeg,
      inStockOnly: _query.inStockOnly,
      minPrice: _query.minPrice,
      maxPrice: _query.maxPrice,
      page: _page + 1,
    );
    result.when(
      success: (data) {
        _page++;
        _hasMore = data.length >= 20;
        state = AsyncValue.data([...current, ...data]);
      },
      failure: (_) => _hasMore = false,
    );
    _isLoadingMore = false;
  }

  void updateQuery(ProductQuery Function(ProductQuery current) update) {
    _query = update(_query);
    load();
  }
}

final productListProvider =
    StateNotifierProvider.autoDispose<ProductListNotifier, AsyncValue<List<Product>>>((ref) {
  return ProductListNotifier(ref.watch(productRepositoryProvider), const ProductQuery());
});

final searchSuggestionsProvider = FutureProvider.autoDispose.family<List<String>, String>((ref, q) async {
  if (q.trim().isEmpty) return const [];
  final result = await ref.watch(productRepositoryProvider).getSearchSuggestions(q);
  return result.when(success: (data) => data, failure: (_) => const []);
});
