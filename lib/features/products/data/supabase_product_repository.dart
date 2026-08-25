import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/result.dart';
import '../domain/pack_price.dart';
import '../domain/product.dart';
import '../domain/product_category.dart';
import '../domain/product_repository.dart';
import '../domain/product_review.dart';

/// Live product catalog backed by Supabase (PostgreSQL + RLS).
///
/// Mapping notes (so the mobile UI stays identical to the seed catalog):
///  * The app's [Product.id] / [ProductCategory.id] use the DB `slug`, not the
///    UUID — this preserves cart/wishlist keys already stored on users' devices.
///  * DB stores `price` (regular) + `sale_price` (<= price). The app model uses
///    `price` (selling) + `compareAtPrice` (struck-through). So:
///        product.price         = sale_price ?? price
///        product.compareAtPrice = (sale_price != null) ? price : null
class SupabaseProductRepository implements ProductRepository {
  SupabaseProductRepository(this._client);

  final SupabaseClient _client;

  static const _select =
      '*, category:categories(slug, name)';

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.success(await action());
    } on PostgrestException catch (e) {
      return Result.failure(AppFailure.server(e.message));
    } on TimeoutException {
      return Result.failure(AppFailure.network());
    } catch (e) {
      final s = e.toString().toLowerCase();
      if (s.contains('socket') || s.contains('network') || s.contains('connection') || s.contains('failed host')) {
        return Result.failure(AppFailure.network());
      }
      return Result.failure(AppFailure.unknown(e.toString()));
    }
  }

  Product _mapProduct(Map<String, dynamic> row) {
    final category = row['category'] as Map<String, dynamic>?;
    final categorySlug = (category?['slug'] as String?) ?? '';
    final categoryName = (category?['name'] as String?) ?? '';

    final regular = (row['price'] as num?)?.toDouble() ?? 0;
    final saleRaw = row['sale_price'];
    final sale = saleRaw == null ? null : (saleRaw as num).toDouble();
    final hasDiscount = sale != null;

    final slug = row['slug'] as String;
    final gallery = (row['additional_images'] as List?)?.map((e) => e.toString()).toList() ?? const [];

    // `pack_sizes` is the single source of truth for per-size pricing. It
    // holds either the new shape [{size, price}] or a legacy plain-string
    // array ["100g", ...]. Parse both: objects carry real prices; strings
    // fall back to the multiplier ladder off the base selling price.
    final rawPacks = row['pack_sizes'] as List?;
    final sellingBase = sale ?? regular;
    final packPricing = <PackPrice>[];
    if (rawPacks != null) {
      for (final entry in rawPacks) {
        if (entry is Map) {
          final size = entry['size']?.toString();
          final priceVal = entry['price'];
          if (size != null && size.isNotEmpty) {
            packPricing.add(PackPrice(
              size: size,
              price: priceVal is num ? priceVal.toDouble() : sellingBase,
            ));
          }
        }
      }
    }
    if (packPricing.isEmpty) {
      // Legacy string array (or empty) — derive the ladder from the base.
      final labels = rawPacks?.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
      if (labels != null && labels.isNotEmpty) {
        for (final size in labels) {
          final mult = PackPrice.multipliers[size] ?? 1.0;
          packPricing.add(PackPrice(size: size, price: (sellingBase * mult).roundToDouble()));
        }
      } else {
        packPricing.addAll(PackPrice.defaultsFor(sellingBase));
      }
    }
    final packSizes = packPricing.map((p) => p.size).toList();

    final availability = switch (row['stock_status'] as String?) {
      'out_of_stock' => ProductAvailability.outOfStock,
      'coming_soon' => ProductAvailability.comingSoon,
      _ => ProductAvailability.inStock,
    };

    return Product(
      id: slug,
      slug: slug,
      name: row['name'] as String? ?? '',
      categoryId: categorySlug,
      categoryName: categoryName,
      description: row['description'] as String? ?? '',
      shortDescription: row['short_description'] as String? ?? '',
      price: hasDiscount ? sale : regular,
      compareAtPrice: hasDiscount ? regular : null,
      currency: row['currency'] as String? ?? 'SAR',
      imageUrl: row['image_url'] as String? ?? '',
      galleryImages: gallery,
      packSizes: packSizes.isEmpty ? const ['100g', '250g', '500g', '1kg'] : packSizes,
      packPricing: packPricing,
      rating: (row['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: (row['review_count'] as num?)?.toInt() ?? 0,
      availability: availability,
      isFeatured: row['is_featured'] as bool? ?? false,
      isVeg: row['is_veg'] as bool? ?? false,
      tags: [if (categoryName.isNotEmpty) categoryName, if (hasDiscount) 'Offer'],
      sku: (row['sku'] as String?) ?? slug.toUpperCase(),
    );
  }

  Future<String?> _categoryUuidForSlug(String slug) async {
    final row = await _client
        .from('categories')
        .select('id')
        .eq('slug', slug)
        .maybeSingle();
    return row?['id'] as String?;
  }

  @override
  Future<Result<List<ProductCategory>>> getCategories() {
    return _guard(() async {
      final rows = await _client
          .from('categories')
          .select('id, slug, name, description, image_url, sort_order')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      final categories = <ProductCategory>[];
      for (final row in (rows as List).cast<Map<String, dynamic>>()) {
        final count = await _client
            .from('products')
            .count(CountOption.exact)
            .eq('category_id', row['id'] as Object)
            .eq('is_active', true);
        categories.add(ProductCategory(
          id: row['slug'] as String,
          name: row['name'] as String,
          slug: row['slug'] as String,
          description: row['description'] as String? ?? '',
          imageUrl: row['image_url'] as String? ?? '',
          productCount: count,
        ));
      }
      return categories;
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
      var filter = _client.from('products').select(_select).eq('is_active', true);

      if (categoryId != null && categoryId.isNotEmpty) {
        final uuid = await _categoryUuidForSlug(categoryId);
        if (uuid == null) return <Product>[];
        filter = filter.eq('category_id', uuid);
      }
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim();
        filter = filter.or('name.ilike.%$q%,sku.ilike.%$q%');
      }
      if (isVeg != null) filter = filter.eq('is_veg', isVeg);
      if (inStockOnly == true) filter = filter.eq('stock_status', 'in_stock');
      if (minPrice != null) filter = filter.gte('price', minPrice);
      if (maxPrice != null) filter = filter.lte('price', maxPrice);

      final transform = switch (sort) {
        ProductSortOption.priceLowToHigh => filter.order('price', ascending: true),
        ProductSortOption.priceHighToLow => filter.order('price', ascending: false),
        ProductSortOption.rating => filter.order('rating', ascending: false),
        ProductSortOption.nameAZ => filter.order('name', ascending: true),
        ProductSortOption.newest => filter.order('created_at', ascending: false),
      };

      final start = (page - 1) * pageSize;
      final rows = await transform.range(start, start + pageSize - 1);
      return (rows as List).cast<Map<String, dynamic>>().map(_mapProduct).toList();
    });
  }

  @override
  Future<Result<Product>> getProductById(String id) {
    return _guard(() async {
      final row = await _client
          .from('products')
          .select(_select)
          .eq('slug', id)
          .eq('is_active', true)
          .maybeSingle();
      if (row == null) return null;
      return _mapProduct(row);
    }).then((result) => result.when(
          success: (product) =>
              product == null ? Result<Product>.failure(AppFailure.notFound()) : Result.success(product),
          failure: Result<Product>.failure,
        ));
  }

  @override
  Future<Result<List<Product>>> getFeaturedProducts() {
    return _guard(() async {
      final rows = await _client
          .from('products')
          .select(_select)
          .eq('is_active', true)
          .eq('is_featured', true)
          .order('sort_order', ascending: true)
          .limit(12);
      return (rows as List).cast<Map<String, dynamic>>().map(_mapProduct).toList();
    });
  }

  @override
  Future<Result<List<Product>>> getLatestProducts() {
    return _guard(() async {
      final rows = await _client
          .from('products')
          .select(_select)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(10);
      return (rows as List).cast<Map<String, dynamic>>().map(_mapProduct).toList();
    });
  }

  @override
  Future<Result<List<Product>>> getRelatedProducts(String productId) {
    return _guard(() async {
      final self = await _client
          .from('products')
          .select('category_id')
          .eq('slug', productId)
          .maybeSingle();
      final categoryId = self?['category_id'];
      if (categoryId == null) return <Product>[];
      final rows = await _client
          .from('products')
          .select(_select)
          .eq('is_active', true)
          .eq('category_id', categoryId as Object)
          .neq('slug', productId)
          .limit(8);
      return (rows as List).cast<Map<String, dynamic>>().map(_mapProduct).toList();
    });
  }

  @override
  Future<Result<List<ProductReview>>> getReviews(String productId) async {
    // No reviews backend in scope — return empty so the UI shows the
    // "No reviews yet" empty state rather than fabricated reviews.
    return const Result.success(<ProductReview>[]);
  }

  @override
  Future<Result<List<String>>> getSearchSuggestions(String query) {
    if (query.trim().isEmpty) return Future.value(const Result.success(<String>[]));
    return _guard(() async {
      final q = query.trim();
      final rows = await _client
          .from('products')
          .select('name')
          .eq('is_active', true)
          .ilike('name', '%$q%')
          .limit(6);
      return (rows as List).map((r) => r['name'] as String).toList();
    });
  }
}
