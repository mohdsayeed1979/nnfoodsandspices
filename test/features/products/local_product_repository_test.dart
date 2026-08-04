import 'package:flutter_test/flutter_test.dart';
import 'package:nn_food_spices/features/products/data/local_product_repository.dart';
import 'package:nn_food_spices/features/products/domain/product_repository.dart';

void main() {
  late LocalProductRepository repository;

  setUp(() {
    repository = LocalProductRepository();
  });

  group('LocalProductRepository', () {
    test('getCategories returns the four real NN Food & Spices categories', () async {
      final result = await repository.getCategories();
      final categories = result.when(success: (d) => d, failure: (_) => []);
      expect(categories.length, 4);
      expect(categories.map((c) => c.id), containsAll(['veg-spices', 'pure-spices', 'non-veg-spices', 'other-spices']));
    });

    test('getProducts filters by categoryId', () async {
      final result = await repository.getProducts(categoryId: 'non-veg-spices');
      final products = result.when(success: (d) => d, failure: (_) => []);
      expect(products, isNotEmpty);
      expect(products.every((p) => p.categoryId == 'non-veg-spices'), isTrue);
    });

    test('getProducts filters by search query across name', () async {
      final result = await repository.getProducts(query: 'biryani');
      final products = result.when(success: (d) => d, failure: (_) => []);
      expect(products, isNotEmpty);
      expect(products.every((p) => p.name.toLowerCase().contains('biryani')), isTrue);
    });

    test('getProducts sorts by price low to high', () async {
      final result = await repository.getProducts(sort: ProductSortOption.priceLowToHigh, pageSize: 100);
      final products = result.when(success: (d) => d, failure: (_) => []);
      for (var i = 1; i < products.length; i++) {
        expect(products[i].price, greaterThanOrEqualTo(products[i - 1].price));
      }
    });

    test('getProducts respects isVeg filter', () async {
      final result = await repository.getProducts(isVeg: false, pageSize: 100);
      final products = result.when(success: (d) => d, failure: (_) => []);
      expect(products, isNotEmpty);
      expect(products.every((p) => !p.isVeg), isTrue);
    });

    test('getProductById returns not-found failure for unknown id', () async {
      final result = await repository.getProductById('does-not-exist');
      final failure = result.when(success: (_) => null, failure: (f) => f);
      expect(failure?.code, 'not_found');
    });

    test('getRelatedProducts excludes the product itself and matches category', () async {
      final all = await repository.getProducts(categoryId: 'veg-spices', pageSize: 100);
      final product = all.when(success: (d) => d.first, failure: (_) => throw StateError('no products'));
      final relatedResult = await repository.getRelatedProducts(product.id);
      final related = relatedResult.when(success: (d) => d, failure: (_) => []);
      expect(related.any((p) => p.id == product.id), isFalse);
      expect(related.every((p) => p.categoryId == product.categoryId), isTrue);
    });

    test('getSearchSuggestions returns empty for blank query', () async {
      final result = await repository.getSearchSuggestions('   ');
      final suggestions = result.when(success: (d) => d, failure: (_) => ['error']);
      expect(suggestions, isEmpty);
    });
  });
}
