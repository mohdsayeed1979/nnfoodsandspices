import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/product_repository.dart';
import '../providers/product_providers.dart';

class FilterSortSheet extends StatefulWidget {
  const FilterSortSheet({super.key, required this.notifier});
  final ProductListNotifier notifier;

  @override
  State<FilterSortSheet> createState() => _FilterSortSheetState();
}

class _FilterSortSheetState extends State<FilterSortSheet> {
  late ProductSortOption _sort = widget.notifier.query.sort;
  late bool _inStockOnly = widget.notifier.query.inStockOnly ?? false;
  late RangeValues _priceRange = RangeValues(
    widget.notifier.query.minPrice ?? 0,
    widget.notifier.query.maxPrice ?? 300,
  );

  static const _sortLabels = {
    ProductSortOption.newest: 'Newest',
    ProductSortOption.priceLowToHigh: 'Price: Low to High',
    ProductSortOption.priceHighToLow: 'Price: High to Low',
    ProductSortOption.rating: 'Top Rated',
    ProductSortOption.nameAZ: 'Name: A-Z',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              const Text('Sort By', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sortLabels.entries.map((e) {
                  return ChoiceChip(
                    label: Text(e.value),
                    selected: _sort == e.key,
                    onSelected: (_) => setState(() => _sort = e.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text('Price Range', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 300,
                divisions: 30,
                activeColor: AppColors.primaryGreen,
                labels: RangeLabels('₹${_priceRange.start.round()}', '₹${_priceRange.end.round()}'),
                onChanged: (v) => setState(() => _priceRange = v),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('In stock only', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                value: _inStockOnly,
                activeThumbColor: AppColors.primaryGreen,
                onChanged: (v) => setState(() => _inStockOnly = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _sort = ProductSortOption.newest;
                          _inStockOnly = false;
                          _priceRange = const RangeValues(0, 300);
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.notifier.updateQuery((q) => q.copyWith(
                              sort: _sort,
                              inStockOnly: _inStockOnly,
                              minPrice: _priceRange.start,
                              maxPrice: _priceRange.end,
                            ));
                        Navigator.of(context).pop();
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
