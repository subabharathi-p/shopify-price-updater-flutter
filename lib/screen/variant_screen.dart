import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../product.dart';

class VariantListScreen extends StatefulWidget {
  final Product product;

  const VariantListScreen({super.key, required this.product});

  @override
  State<VariantListScreen> createState() => _VariantListScreenState();
}

class _VariantListScreenState extends State<VariantListScreen> {
  final int pageSize = 50; // Load 50 variants at a time
  late List<Variant> displayedVariants;
  int currentMax = 0;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    displayedVariants = [];
    _scrollController = ScrollController()..addListener(_scrollListener);
    _loadMore();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent) {
      _loadMore();
    }
  }

  void _loadMore() {
    final nextMax = currentMax + pageSize;
    if (currentMax >= widget.product.variants.length) return;

    setState(() {
      displayedVariants.addAll(widget.product.variants
          .sublist(currentMax,
              nextMax > widget.product.variants.length
                  ? widget.product.variants.length
                  : nextMax)
          .map((v) => v));
      currentMax = displayedVariants.length;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: "₹");
    return Scaffold(
      appBar: AppBar(title: Text(widget.product.title)),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: displayedVariants.length + 1,
        itemBuilder: (context, index) {
          if (index == displayedVariants.length) {
            if (displayedVariants.length == widget.product.variants.length) {
              return const SizedBox(height: 60); // End padding
            } else {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              );
            }
          }

          final v = displayedVariants[index];
          return ListTile(
            title: Text(v.title),
            subtitle: Text("SKU: ${v.sku ?? '-'}"),
            trailing: Text(currencyFormat.format(v.price)),
          );
        },
      ),
    );
  }
}


