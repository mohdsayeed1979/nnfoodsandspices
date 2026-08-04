import '../../../core/error/result.dart';
import '../domain/product.dart';
import '../domain/product_category.dart';
import '../domain/product_repository.dart';
import '../domain/product_review.dart';
import 'product_seed_data.dart';

/// In-memory implementation backed by the real scraped NN Food & Spices
/// catalog. Used while no WooCommerce API credentials are configured — see
/// [ProductRepositoryConfig].
class LocalProductRepository implements ProductRepository {
  final _products = ProductSeedData.products;
  final _categories = ProductSeedData.categories;

  Future<void> _simulateLatency() => Future.delayed(const Duration(milliseconds: 350));

  @override
  Future<Result<List<ProductCategory>>> getCategories() async {
    await _simulateLatency();
    return Result.success(_categories);
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
  }) async {
    await _simulateLatency();
    var results = _products.where((p) {
      if (categoryId != null && p.categoryId != categoryId) return false;
      if (query != null && query.trim().isNotEmpty) {
        final q = query.toLowerCase();
        if (!p.name.toLowerCase().contains(q) &&
            !p.categoryName.toLowerCase().contains(q) &&
            !p.tags.any((t) => t.toLowerCase().contains(q))) {
          return false;
        }
      }
      if (isVeg != null && p.isVeg != isVeg) return false;
      if (inStockOnly == true && !p.isInStock) return false;
      if (minPrice != null && p.price < minPrice) return false;
      if (maxPrice != null && p.price > maxPrice) return false;
      return true;
    }).toList();

    switch (sort) {
      case ProductSortOption.priceLowToHigh:
        results.sort((a, b) => a.price.compareTo(b.price));
      case ProductSortOption.priceHighToLow:
        results.sort((a, b) => b.price.compareTo(a.price));
      case ProductSortOption.rating:
        results.sort((a, b) => b.rating.compareTo(a.rating));
      case ProductSortOption.nameAZ:
        results.sort((a, b) => a.name.compareTo(b.name));
      case ProductSortOption.newest:
        results.sort((a, b) => (b.isLatest ? 1 : 0).compareTo(a.isLatest ? 1 : 0));
    }

    final start = (page - 1) * pageSize;
    if (start >= results.length) return const Result.success(<Product>[]);
    final end = (start + pageSize).clamp(0, results.length);
    return Result.success(results.sublist(start, end));
  }

  @override
  Future<Result<Product>> getProductById(String id) async {
    await _simulateLatency();
    final match = _products.where((p) => p.id == id);
    if (match.isEmpty) return Result.failure(AppFailure.notFound());
    return Result.success(match.first);
  }

  @override
  Future<Result<List<Product>>> getFeaturedProducts() async {
    await _simulateLatency();
    return Result.success(_products.where((p) => p.isFeatured).toList());
  }

  @override
  Future<Result<List<Product>>> getLatestProducts() async {
    await _simulateLatency();
    return Result.success(_products.where((p) => p.isLatest).toList());
  }

  @override
  Future<Result<List<Product>>> getRelatedProducts(String productId) async {
    await _simulateLatency();
    final match = _products.where((p) => p.id == productId);
    if (match.isEmpty) return const Result.success(<Product>[]);
    final product = match.first;
    final related = _products
        .where((p) => p.categoryId == product.categoryId && p.id != productId)
        .take(8)
        .toList();
    return Result.success(related);
  }

  @override
  Future<Result<List<ProductReview>>> getReviews(String productId) async {
    await _simulateLatency();
    final match = _products.where((p) => p.id == productId);
    if (match.isEmpty) return const Result.success(<ProductReview>[]);
    final product = match.first;
    if (product.reviewCount == 0) return const Result.success(<ProductReview>[]);
    final sampleAuthors = [
      'Priya Sharma', 'Rahul Verma', 'Ayesha Khan', 'Sanjay Reddy',
      'Fatima Ali', 'Vikram Rao', 'Lakshmi Naidu', 'Mohammed Irfan',
    ];
    final count = product.reviewCount.clamp(0, 6);
    final reviews = List.generate(count, (i) {
      return ProductReview(
        id: '${product.id}-review-$i',
        productId: product.id,
        authorName: sampleAuthors[i % sampleAuthors.length],
        rating: (product.rating - 0.3 + (i % 3) * 0.3).clamp(3.0, 5.0),
        comment: _reviewComments[i % _reviewComments.length],
        createdAt: DateTime.now().subtract(Duration(days: 5 + i * 11)),
        verifiedPurchase: i % 3 != 0,
      );
    });
    return Result.success(reviews);
  }

  @override
  Future<Result<List<String>>> getSearchSuggestions(String query) async {
    if (query.trim().isEmpty) return const Result.success(<String>[]);
    final q = query.toLowerCase();
    final matches = _products
        .where((p) => p.name.toLowerCase().contains(q))
        .map((p) => p.name)
        .toSet()
        .take(6)
        .toList();
    return Result.success(matches);
  }

  static const _reviewComments = [
    'Excellent aroma and freshness, tastes just like homemade.',
    'Great quality spices, will definitely order again.',
    'Packaging was good and the masala was very flavourful.',
    'Authentic taste, perfect blend of spices.',
    'Good product but delivery took a couple of extra days.',
    'My family loved it — rich flavour without being too spicy.',
  ];
}
