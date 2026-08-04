import '../../../core/error/result.dart';
import 'product.dart';
import 'product_category.dart';
import 'product_review.dart';

enum ProductSortOption { newest, priceLowToHigh, priceHighToLow, rating, nameAZ }

abstract interface class ProductRepository {
  Future<Result<List<ProductCategory>>> getCategories();

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
  });

  Future<Result<Product>> getProductById(String id);

  Future<Result<List<Product>>> getFeaturedProducts();

  Future<Result<List<Product>>> getLatestProducts();

  Future<Result<List<Product>>> getRelatedProducts(String productId);

  Future<Result<List<ProductReview>>> getReviews(String productId);

  Future<Result<List<String>>> getSearchSuggestions(String query);
}
