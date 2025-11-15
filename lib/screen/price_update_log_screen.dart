// ✅ PriceUpdateLogScreen.dart — Final Clean Version (No Connected Store / No Stats Row)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/db_services.dart';
import '../services/shopify_service.dart';
import '../models/update_log.dart';
import '../product.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cross_file/cross_file.dart';

class PriceUpdateLogScreen extends StatefulWidget {
  final VoidCallback onPricesUpdated;
  final List<Product> allProducts;
  final ShopifyService shopifyService;

  const PriceUpdateLogScreen({
    super.key,
    required this.onPricesUpdated,
    required this.allProducts,
    required this.shopifyService,
  });

  @override
  State<PriceUpdateLogScreen> createState() => _PriceUpdateLogScreenState();
}

class _PriceUpdateLogScreenState extends State<PriceUpdateLogScreen> {
  List<UpdateLogSummary> summaryLogs = [];
  List<UpdateLogSummary> filteredLogs = [];
  bool isLoading = true;

  String? selectedCategory;
  String? selectedSubcategory;
  String? selectedOperation;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  String searchText = "";
  String? currentShopDomain;

  static const Color kBg = Color(0xFFFDF6F2);
  static const Color kPrimary = Color(0xFFD7A4A4);
  static const Color kText = Color(0xFF3E3E3E);
  static const Color kCard = Color(0xFFFFFFFF);
  static const Color kGold = Color(0xFFE8C547);
  static const Color kLavender = Color(0xFFE3D0D8);

  @override
  void initState() {
    super.initState();
    fetchLogs();
  }

  Future<void> fetchLogs() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      currentShopDomain = prefs.getString('shopDomain');
      summaryLogs = await DBService.getSummaryLogs();

      if (currentShopDomain != null && currentShopDomain!.isNotEmpty) {
        summaryLogs = summaryLogs
            .where((log) => log.storeDomain == currentShopDomain)
            .toList();
      }

      for (var log in summaryLogs) {
        await log.ensureVariantDetails();
        for (var v in log.variantDetails) {
          v.oldPrice =
              await DBService.getVariantOldPrice(log.runId, v.variantId) ??
                  v.oldPrice;
          v.newPrice =
              await DBService.getVariantNewPrice(log.runId, v.variantId) ??
                  v.newPrice;
        }
      }
      applyFilters();
    } catch (e) {
      debugPrint('❌ fetchLogs error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void applyFilters() {
    filteredLogs = summaryLogs.where((log) {
      final matchCategory =
          selectedCategory == null || log.category == selectedCategory;
      final matchSubcategory =
          selectedSubcategory == null || log.subCategory == selectedSubcategory;
      final matchOperation =
          selectedOperation == null || log.operation == selectedOperation;
      final matchSearch = searchText.isEmpty ||
          log.variantDetails.any((v) =>
              v.variantName.toLowerCase().contains(searchText.toLowerCase()));
      final matchStartDate = selectedStartDate == null ||
          log.timestamp
              .isAfter(selectedStartDate!.subtract(const Duration(days: 1)));
      final matchEndDate = selectedEndDate == null ||
          log.timestamp.isBefore(selectedEndDate!.add(const Duration(days: 1)));

      return matchCategory &&
          matchSubcategory &&
          matchOperation &&
          matchSearch &&
          matchStartDate &&
          matchEndDate;
    }).toList();
  }

  void _showSnack(String msg, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: success ? Colors.green : Colors.redAccent,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> exportToCSV() async {
    try {
      List<List<dynamic>> rows = [
        [
          "Category",
          "Subcategory",
          "Variant",
          "Old Price",
          "New Price",
          "Operation",
          "Date"
        ]
      ];

      for (var log in filteredLogs) {
        for (var v in log.variantDetails) {
          rows.add([
            log.category,
            log.subCategory ?? "-",
            v.variantName,
            v.oldPrice,
            v.newPrice,
            log.operation,
            DateFormat('dd-MM-yyyy HH:mm').format(log.timestamp),
          ]);
        }
      }

      String csvData = const ListToCsvConverter().convert(rows);
      final dir = await getApplicationDocumentsDirectory();
      final path = "${dir.path}/price_update_logs.csv";
      final file = File(path);
      await file.writeAsString(csvData);
      await Share.shareXFiles([XFile(path)],
          text: "📊 Price Update Logs - CSV Export");
    } catch (e) {
      _showSnack("CSV export failed: $e", success: false);
    }
  }

  Future<void> exportToPDF() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            pw.Center(
              child: pw.Text("Price Update Logs",
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 10),
            ...filteredLogs.map((log) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("${log.category} - ${log.subCategory ?? "-"}",
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Table.fromTextArray(
                    headers: ["Variant", "Old Price", "New Price"],
                    data: log.variantDetails.map((v) {
                      return [
                        v.variantName,
                        "₹${v.oldPrice}",
                        "₹${v.newPrice}",
                      ];
                    }).toList(),
                  ),
                  pw.SizedBox(height: 10),
                ],
              );
            }),
          ],
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final path = "${dir.path}/price_update_logs.pdf";
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(path)],
          text: "📄 Price Update Logs - PDF Export");
    } catch (e) {
      _showSnack("PDF export failed: $e", success: false);
    }
  }

  Widget buildDropdown(
      String label, String? value, List<String> items, Function(String?) onChanged) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: 150,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              color: kPrimary, fontSize: 13, fontWeight: FontWeight.w600),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kPrimary)),
        ),
        icon: const Icon(Icons.expand_more, color: kPrimary),
        value: value,
        items: items
            .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e,
                    style: const TextStyle(
                        color: kText, fontWeight: FontWeight.w500))))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget datePickerButton(
      String label, DateTime? selectedDate, Function(DateTime) onPicked) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.calendar_today, size: 16, color: kPrimary),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: kPrimary),
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: DateTime(2023),
            lastDate: DateTime.now(),
          );
          if (date != null) onPicked(date);
        },
        label: Text(
          selectedDate == null
              ? label
              : DateFormat('dd-MM-yyyy').format(selectedDate),
          style: const TextStyle(
              color: kText, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = summaryLogs.map((e) => e.category).toSet().toList();
    final subcategories = summaryLogs
        .where((e) => e.category == selectedCategory)
        .map((e) => e.subCategory)
        .whereType<String>()
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 4,
        shadowColor: kPrimary.withOpacity(0.4),
        centerTitle: true,
        title: const Text(
          "📜 Price Update Logs",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
        ),
        actions: [
          IconButton(
              tooltip: "Export CSV",
              onPressed: exportToCSV,
              icon:
                  const Icon(Icons.file_copy_outlined, color: Colors.white)),
          IconButton(
              tooltip: "Export PDF",
              onPressed: exportToPDF,
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white)),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              color: kPrimary,
              onRefresh: fetchLogs,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: filteredLogs.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(60),
                        child: Center(
                          child: Text(
                            "No logs found!",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 20),
                        children: [
                          _buildFilterCard(categories, subcategories),
                          ...List.generate(
                            filteredLogs.length,
                            (index) => _buildLogCard(filteredLogs[index]),
                          ),
                        ],
                      ),
              ),
            ),
    );
  }

  // 🔹 Filter Card (no Connected Store)
  Widget _buildFilterCard(List<String> categories, List<String> subcategories) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      color: Colors.transparent,
      margin: const EdgeInsets.all(12),
      child: Card(
        elevation: 5,
        shadowColor: Colors.black12,
        color: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    buildDropdown("Category", selectedCategory, categories, (val) {
                      setState(() {
                        selectedCategory = val;
                        selectedSubcategory = null;
                        applyFilters();
                      });
                    }),
                    if (selectedCategory != null)
                      buildDropdown(
                          "Subcategory", selectedSubcategory, subcategories, (val) {
                        setState(() {
                          selectedSubcategory = val;
                          applyFilters();
                        });
                      }),
                    buildDropdown("Operation", selectedOperation,
                        ["Increase", "Decrease"], (val) {
                      setState(() {
                        selectedOperation = val;
                        applyFilters();
                      });
                    }),
                    datePickerButton("Start Date", selectedStartDate, (date) {
                      setState(() {
                        selectedStartDate = date;
                        applyFilters();
                      });
                    }),
                    datePickerButton("End Date", selectedEndDate, (date) {
                      setState(() {
                        selectedEndDate = date;
                        applyFilters();
                      });
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                decoration: InputDecoration(
                  hintText: "Search by product or variant name...",
                  prefixIcon: const Icon(Icons.search, color: kPrimary),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: kPrimary)),
                ),
                onChanged: (val) {
                  setState(() {
                    searchText = val;
                    applyFilters();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Log Card
  Widget _buildLogCard(UpdateLogSummary log) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      shadowColor: Colors.black12,
      color: Colors.white,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text("${log.category} - ${log.subCategory ?? "-"}",
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: kText, fontSize: 15)),
        subtitle: Text(
          "${log.operation} ${log.valueType} ${log.value}",
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        children: [
          ...log.variantDetails.map((v) => Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Text(v.variantName,
                            style: const TextStyle(
                                color: kText, fontWeight: FontWeight.w500))),
                    Expanded(
                        flex: 4,
                        child: Text("₹${v.oldPrice} → ₹${v.newPrice}",
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold))),
                    Icon(v.success ? Icons.check_circle : Icons.cancel,
                        color: v.success ? Colors.green : Colors.red, size: 18),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButton(
                icon: Icons.undo,
                label: "Undo",
                color: kLavender,
                onTap: () async {
                  await _handleUndoRestore(log, isUndo: true);
                },
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                icon: Icons.restore,
                label: "Restore",
                color: kGold,
                onTap: () async {
                  await _handleUndoRestore(log, isUndo: false);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUndoRestore(UpdateLogSummary log,
      {required bool isUndo}) async {
    _showSnack(isUndo ? "Undoing changes..." : "Restoring prices...");
    try {
      for (var v in log.variantDetails) {
        final double targetPrice = isUndo ? v.oldPrice : v.newPrice;
        bool success = await widget.shopifyService.updateVariantPrice(
          productId: v.productId,
          variantId: v.variantId,
          productName: 'Unknown Product',
          variantName: v.variantName,
          oldPrice: v.oldPrice,
          newPrice: targetPrice,
          runId: "undo_${DateTime.now().millisecondsSinceEpoch}",
        );

        if (success) {
          await DBService.saveCurrentPrice(v.productId, v.variantId, targetPrice);
          v.success = true;
        } else {
          v.success = false;
        }
      }

      await DBService.updateSummaryLogPrices(log, log.variantDetails);
      setState(() {});
      widget.onPricesUpdated();

      _showSnack(
        isUndo
            ? "✅ Undo successful for ${log.category}"
            : "✅ Restore successful for ${log.category}",
        success: true,
      );
    } catch (e) {
      _showSnack("Operation failed: $e", success: false);
      debugPrint("❌ Undo/Restore Exception: $e");
    }
  }
}


