import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/router/app_routes.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../products/presentation/providers/product_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _speech = stt.SpeechToText();
  bool _isListening = false;
  String _query = '';

  Box<String> get _historyBox => Hive.box<String>(HiveBoxes.recentSearches);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _historyBox.put(trimmed.toLowerCase(), trimmed);
    ref.read(productListProvider.notifier).updateQuery((q) => q.copyWith(query: trimmed));
    setState(() => _query = trimmed);
    context.push(AppRoutes.products);
  }

  Future<void> _toggleVoiceSearch() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (_) => setState(() => _isListening = false),
    );
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice search is not available on this device')),
        );
      }
      return;
    }
    setState(() => _isListening = true);
    _speech.listen(
      onResult: (result) {
        _controller.text = result.recognizedWords;
        _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
        setState(() => _query = result.recognizedWords);
        if (result.finalResult) _submit(result.recognizedWords);
      },
    );
  }

  Future<void> _openBarcodeScanner() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _BarcodeScannerScreen()),
    );
    if (code != null && mounted) {
      _controller.text = code;
      _submit(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestionsAsync = ref.watch(searchSuggestionsProvider(_query));
    final history = _historyBox.values.toList().reversed.take(8).toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search for spices, masalas...',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v),
          onSubmitted: _submit,
        ),
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic_rounded : Icons.mic_none_rounded, color: _isListening ? AppColors.primaryOrange : null),
            onPressed: _toggleVoiceSearch,
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: _openBarcodeScanner,
          ),
        ],
      ),
      body: _query.isEmpty
          ? _buildHistory(history)
          : suggestionsAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(16), child: ShimmerBox(height: 40)),
              error: (e, _) => const SizedBox(),
              data: (suggestions) => ListView(
                children: [
                  ...suggestions.map((s) => ListTile(
                        leading: const Icon(Icons.search_rounded),
                        title: Text(s),
                        onTap: () {
                          _controller.text = s;
                          _submit(s);
                        },
                      )),
                  ListTile(
                    leading: const Icon(Icons.arrow_forward_rounded),
                    title: Text('Search for "$_query"'),
                    onTap: () => _submit(_query),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHistory(List<String> history) {
    if (history.isEmpty) {
      return const Center(child: Text('Search for your favourite spices and masalas', style: TextStyle(color: Colors.grey)));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Searches', style: TextStyle(fontWeight: FontWeight.w700)),
            TextButton(onPressed: () => setState(_historyBox.clear), child: const Text('Clear')),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: history.map((h) {
            return ActionChip(
              label: Text(h),
              avatar: const Icon(Icons.history_rounded, size: 16),
              onPressed: () {
                _controller.text = h;
                _submit(h);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _BarcodeScannerScreen extends StatelessWidget {
  const _BarcodeScannerScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: MobileScanner(
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            Navigator.of(context).pop(barcodes.first.rawValue);
          }
        },
      ),
    );
  }
}

class SearchResultsGrid extends ConsumerWidget {
  const SearchResultsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);
    return productsAsync.when(
      loading: () => const ProductGridShimmer(),
      error: (e, _) => const Center(child: Text('Something went wrong')),
      data: (products) => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.62,
        ),
        itemCount: products.length,
        itemBuilder: (context, i) => ProductCard(product: products[i]),
      ),
    );
  }
}
