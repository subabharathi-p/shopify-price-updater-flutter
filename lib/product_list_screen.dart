import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../product.dart';
import '../services/pdf_service.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ProductListScreen extends StatefulWidget {
  final List<Product> products;
  final NumberFormat currencyFormat;
  final VoidCallback onPricesUpdated;
  final Future<void> Function(Product p) onUndo;
  final Future<void> Function(Product p) onRestore;

  const ProductListScreen({
    super.key,
    required this.products,
    required this.currencyFormat,
    required this.onPricesUpdated,
    required this.onUndo,
    required this.onRestore,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  static const Color kBg = Color(0xFFFDF6F2);
  static const Color kPrimary = Color(0xFFD7A4A4);
  static const Color kText = Color(0xFF333333);

  String searchQuery = "";

  List<Product> get filteredProducts {
    if (searchQuery.isEmpty) return widget.products;
    return widget.products.where((p) {
      final matchTitle =
          p.title.toLowerCase().contains(searchQuery.toLowerCase());
      final matchVariant = p.variants.any((v) =>
          v.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (v.sku ?? "").toLowerCase().contains(searchQuery.toLowerCase()));
      return matchTitle || matchVariant;
    }).toList();
  }

  InputDecoration getSearchDecoration() {
    return InputDecoration(
      hintText: "Search by Product Name or SKU...",
      prefixIcon: const Icon(Icons.search, color: kPrimary),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> exportCsv() async {
    final rows = <List<String>>[];
    rows.add(['SKU', 'Product Name', 'RRP']);
    for (var p in widget.products) {
      for (var v in p.variants) {
        rows.add([
          v.sku ?? '-',
          p.title,
          v.price.toStringAsFixed(2),
        ]);
      }
    }

    final csvData = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/product_rrp.csv';
    final file = File(path);
    await file.writeAsString(csvData);
    await Share.shareXFiles([XFile(path)], text: 'Product RRP CSV');
  }

  void refreshProducts() {
    setState(() {});
    widget.onPricesUpdated();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text(
          "Product List",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Export PDF",
            onPressed: () => PdfService.exportBeforeAfterPdf(
                widget.products, widget.currencyFormat.currencySymbol),
          ),
          IconButton(
            icon: const Icon(Icons.file_copy_outlined),
            tooltip: "Export CSV",
            onPressed: exportCsv,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              decoration: getSearchDecoration(),
              onChanged: (v) => setState(() => searchQuery = v),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filteredProducts.isEmpty
                  ? const Center(
                      child: Text(
                        "No products found",
                        style: TextStyle(
                            color: kText,
                            fontSize: 16,
                            fontWeight: FontWeight.w500),
                      ),
                    )
                  : Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            border: TableBorder.all(
                              color: Colors.grey.shade400,
                              width: 1.0,
                            ),
                            headingRowColor:
                                MaterialStateProperty.resolveWith((_) => kPrimary),
                            headingTextStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                            dataTextStyle:
                                const TextStyle(color: kText, fontSize: 13),
                            columns: const [
                              DataColumn(label: Text("SKU")),
                              DataColumn(label: Text("Product Name")),
                              DataColumn(label: Text("RRP")),
                            ],
                            rows: [
                              for (var p in filteredProducts)
                                for (var v in p.variants)
                                  DataRow(cells: [
                                    DataCell(Text(v.sku ?? '-')),
                                    DataCell(Text(p.title)),
                                    DataCell(Text(widget.currencyFormat.format(v.price))),
                                  ])
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
