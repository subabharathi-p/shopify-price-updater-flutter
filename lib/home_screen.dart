// ✅ HomeScreen.dart — Final Fixed Version (Part 1 / 2)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shopify_pricesync_v2/product.dart';
import 'package:shopify_pricesync_v2/screen/analytics_dashboard_screen.dart';
import 'package:shopify_pricesync_v2/services/shopify_service.dart';
import 'package:shopify_pricesync_v2/services/db_services.dart';
import 'package:shopify_pricesync_v2/models/price_update_log.dart';
import 'package:shopify_pricesync_v2/models/update_log.dart';
import 'package:shopify_pricesync_v2/screen/price_update_log_screen.dart';
import 'package:shopify_pricesync_v2/product_list_screen.dart';
import 'package:shopify_pricesync_v2/screen/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final String? shopDomain;
  final String? accessToken;

  const HomeScreen({super.key, this.shopDomain, this.accessToken});

  static final GlobalKey<_HomeScreenState> globalKey =
      GlobalKey<_HomeScreenState>();
  static late _HomeScreenState instance;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ShopifyService? _shopifyService;
  List<Product> allProducts = [];
  List<Product> filteredProducts = [];

  String? selectedCategory;
  String? selectedSubcategory;
  String operationType = 'Increase';
  String valueType = 'Fixed';
  double updateValue = 0.0;
  double dynamicRoundValue = 0;

  double priceFrom = 0.0;
  double priceTo = 1000000.0;
  String productNameFilter = '';
  String skuFilter = '';

  List<String> categories = [];
  Map<String, List<String>> subcategories = {};

  bool isLoading = false;
  int _processed = 0;
  int _total = 0;

  String currencySymbol = '₹';
  late NumberFormat currencyFormat;

  static const Color kBg = Color(0xFFF8EDEE);
  static const Color kPrimary = Color(0xFFD7A4A4);
  static const Color kText = Color(0xFF9B6C6C);
  static const Color kCard = Color(0xFFFFF8F8);

  final _scrollController = ScrollController();
  String? shopDomain;
  String? accessToken;

  final TextStyle _sectionTitle =
      const TextStyle(fontWeight: FontWeight.w700, fontSize: 16);
  final TextStyle _labelStyle =
      const TextStyle(fontSize: 13, color: Colors.black54);

 @override
void initState() {
  super.initState();
  HomeScreen.instance = this;

  currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: currencySymbol);

  initHive();

  // ✅ Wait properly before calling autoConnect
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await Future.delayed(const Duration(seconds: 2));
    debugPrint("🚀 Checking for saved Shopify credentials...");
    await autoConnect();
  });
}

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> initHive() async {
    await DBService.initDB();
  }

Future<void> autoConnect() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    // Get saved credentials
    final domain = prefs.getString('shopDomain') ?? '';
    final token = prefs.getString('accessToken') ?? '';

    debugPrint('🟢 AutoConnect → Domain: $domain | Token: ${token.isNotEmpty ? "••••••" : "EMPTY"}');

    // If nothing stored, skip
    if (domain.isEmpty || token.isEmpty) {
      debugPrint('⚠️ No credentials found. Skipping auto-connect.');
      return;
    }

    // Prevent reconnect loops
    if (isLoading || _shopifyService != null) {
      debugPrint('⚠️ Already connected or still loading.');
      return;
    }

    // Show status & connect
    setState(() => isLoading = true);
    showSnackbar('🔄 Auto-connecting to Shopify...');

    await connectAndFetch(domain, token);

    if (allProducts.isNotEmpty) {
      debugPrint('✅ Auto-connected. Products: ${allProducts.length}');
      showSnackbar('✅ Auto-connected successfully!');
    } else {
      debugPrint('⚠️ AutoConnect done but no products found.');
      showSnackbar('⚠️ No products found. Please verify your token.');
    }
  } catch (e) {
    debugPrint('❌ AutoConnect Error: $e');
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}

void updateCurrencySymbol(String symbol) {
    if (!mounted) return;
    setState(() {
      currencySymbol = symbol;
      currencyFormat =
          NumberFormat.currency(locale: 'en_IN', symbol: currencySymbol);
    });
  }

  Future<void> connectAndFetch(String? domain, String? token) async {
    if (!mounted) return;
    if (domain == null || domain.isEmpty || token == null || token.isEmpty) {
      showSnackbar('Shop domain or access token is empty!');
      return;
    }

    setState(() => isLoading = true);
    shopDomain = domain;
    accessToken = token;
    _shopifyService = ShopifyService(shopDomain: domain, accessToken: token);

    try {
      allProducts = await _shopifyService!.fetchProducts();
      debugPrint("Fetched products count: ${allProducts.length}");
      if (allProducts.isEmpty) {
        debugPrint("⚠️ No products fetched — check token or permissions.");
      }
      buildDynamicCategories();
      filterProducts();
    } catch (e) {
      showSnackbar('Error fetching products: $e');
      debugPrint('Error fetching products: $e');
    }

    if (mounted) setState(() => isLoading = false);
  }

  // -------------------- CORE LOGIC --------------------

  void buildDynamicCategories() {
    final Set<String> catSet = {};
    final Map<String, Set<String>> subMap = {};

    for (var p in allProducts) {
      final pt = (p.productType ?? '').trim();
      final catKey = pt.isNotEmpty ? pt : 'Unspecified';
      catSet.add(catKey);

      try {
        final dynamic tagsField = p.tags;
        List<String> tagsList = [];

        if (tagsField is String) {
          tagsList = tagsField
              .split(',')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toList();
        } else if (tagsField is List) {
          tagsList = tagsField
              .map((e) => e.toString().trim())
              .where((t) => t.isNotEmpty)
              .toList();
        }

        if (tagsList.isNotEmpty) {
          final setForCat = subMap.putIfAbsent(catKey, () => <String>{});
          for (var t in tagsList) setForCat.add(t);
        }
      } catch (e) {
        debugPrint('Error parsing tags for product ${p.id}: $e');
      }
    }

    categories = catSet.toList()..sort();
    subcategories = {
      for (var entry in subMap.entries)
        entry.key: entry.value.toList()..sort(),
    };

    debugPrint("✅ Built categories: $categories");
    debugPrint("✅ Built subcategories: $subcategories");
  }

  int _roundPriceToEndingInt(int price, int ending) {
    if (ending < 0) ending = 0;
    if (ending > 99) ending = ending % 100;

    final int base = (price ~/ 100) * 100;
    int candidate = base + ending;
    if (candidate < price) candidate += 100;
    return candidate;
  }

  double _applyDynamicRounding(double price) {
    if (dynamicRoundValue <= 0) return price;

    if (dynamicRoundValue < 100) {
      final int intPrice = price.round();
      final int ending = dynamicRoundValue.round();
      final int rounded = _roundPriceToEndingInt(intPrice, ending);
      return rounded.toDouble();
    } else {
      final rounded =
          (price / dynamicRoundValue).ceilToDouble() * dynamicRoundValue;
      return rounded;
    }
  }

  void filterProducts() {
    filteredProducts = allProducts.where((p) {
      final pt = (p.productType ?? '').trim();
      final title = (p.title ?? '').trim();

      final nameMatch = productNameFilter.trim().isEmpty ||
          title.toLowerCase().contains(productNameFilter.trim().toLowerCase());

      final skuMatch = skuFilter.trim().isEmpty ||
          p.variants.any(
            (v) =>
                v.sku?.toLowerCase().contains(skuFilter.trim().toLowerCase()) ??
                false,
          );

      final priceMatch = p.variants.any((v) {
        final priceToCheck = v.afterPrice ?? v.price ?? 0;
        double roundedPrice = dynamicRoundValue > 0
            ? _applyDynamicRounding(priceToCheck)
            : priceToCheck;
        return roundedPrice >= priceFrom && roundedPrice <= priceTo;
      });

      bool categoryMatch = true;
      bool subcategoryMatch = true;

      if (selectedCategory != null && selectedCategory!.isNotEmpty) {
        final actualCategory = (pt.isNotEmpty) ? pt : 'Unspecified';
        categoryMatch = actualCategory == selectedCategory;
      }

      if (selectedSubcategory != null && selectedSubcategory!.isNotEmpty) {
        bool found = false;
        try {
          final dynamic tagsField = p.tags;
          if (tagsField is String) {
            final tagsList = tagsField
                .split(',')
                .map((t) => t.trim().toLowerCase())
                .where((t) => t.isNotEmpty)
                .toList();
            found = tagsList.contains(selectedSubcategory!.toLowerCase());
          } else if (tagsField is List) {
            final tagsList = tagsField
                .map((e) => e.toString().trim().toLowerCase())
                .where((t) => t.isNotEmpty)
                .toList();
            found = tagsList.contains(selectedSubcategory!.toLowerCase());
          }
        } catch (e) {
          debugPrint('Error checking tags for subcategory: $e');
        }

        if (!found) {
          final ptLower = (p.productType ?? '').toLowerCase();
          found = ptLower == selectedSubcategory!.toLowerCase();
        }

        subcategoryMatch = found;
      }

      return categoryMatch &&
          subcategoryMatch &&
          nameMatch &&
          skuMatch &&
          priceMatch;
    }).toList();

    if (mounted) setState(() {});
    debugPrint("✅ Filtered products count: ${filteredProducts.length}");
  }

  // 🧮 Rest of your core logic continues below (Part 2)
  // 🧮 --- PRICE UPDATE & UNDO / RESTORE LOGIC ---

  double calculateNewPrice(double oldPrice) {
    double newPrice = oldPrice;

    if (updateValue > 0) {
      if (valueType == 'Fixed') {
        newPrice = operationType == 'Increase'
            ? oldPrice + updateValue
            : oldPrice - updateValue;
      } else {
        final change = (oldPrice * updateValue) / 100;
        newPrice = operationType == 'Increase'
            ? oldPrice + change
            : oldPrice - change;
      }
    }

    if (dynamicRoundValue > 0) newPrice = _applyDynamicRounding(newPrice);
    if (newPrice < 0) newPrice = 0;
    return double.parse(newPrice.toStringAsFixed(2));
  }

  Future<void> applyPriceUpdate() async {
    if (_shopifyService == null) {
      showSnackbar('Connect to Shopify store first');
      return;
    }
    if (updateValue <= 0 && dynamicRoundValue <= 0) {
      showSnackbar('Enter a valid value or set rounding');
      return;
    }
    if (filteredProducts.isEmpty) {
      showSnackbar('No products selected for update');
      return;
    }

    _processed = 0;
    _total = filteredProducts.fold(
      0,
      (prev, p) => prev + p.variants.where((v) => v.price != null).length,
    );

    final runTimestamp = DateTime.now();
    final runId = runTimestamp.toIso8601String();

    if (mounted) setState(() => isLoading = true);

    int success = 0;
    int failed = 0;

    for (var p in filteredProducts) {
      final futures = p.variants.where((v) => v.price != null).map((v) async {
        final oldPrice = double.tryParse(v.price.toString()) ?? 0.0;
        final newPrice = calculateNewPrice(oldPrice);
        final localRunId = "RUN_${DateTime.now().millisecondsSinceEpoch}";

        try {
          final ok = await _shopifyService!.updateVariantPrice(
            productId: p.id.toString(),
            variantId: v.id.toString(),
            productName: p.title ?? '',
            variantName: v.title ?? '',
            oldPrice: oldPrice,
            newPrice: newPrice,
            runId: localRunId,
          );

          v.beforePrice ??= oldPrice;
          v.afterPrice = newPrice;
          v.price = newPrice;

          await DBService.savePriceUpdate(
            PriceUpdateLog(
              productId: p.id.toString(),
              variantId: v.id.toString(),
              productName: p.title ?? '',
              variantName: v.title ?? '',
              oldPrice: oldPrice,
              newPrice: newPrice,
              success: ok,
              timestamp: runTimestamp,
              runId: localRunId,
            ),
          );

          ok ? success++ : failed++;
        } catch (e) {
          debugPrint('Failed updating variant ${v.id}: $e');
          failed++;
        } finally {
          _processed++;
          if (mounted) setState(() {});
        }
      }).toList();

      await Future.wait(futures);
    }

    await DBService.addSummaryLog(
      UpdateLogSummary(
        category: selectedCategory ?? 'All',
        subCategory: selectedSubcategory,
        operation: operationType,
        valueType: valueType,
        value: updateValue,
        rounding: dynamicRoundValue > 0
            ? dynamicRoundValue.toStringAsFixed(2)
            : "None",
        total: _total,
        success: success,
        failed: failed,
        timestamp: runTimestamp,
        runId: runId,
        variantDetails: filteredProducts
            .expand(
              (p) => p.variants.map(
                (v) => VariantDetail(
                  variantId: v.id.toString(),
                  productId: p.id.toString(),
                  productName: p.title ?? '',
                  variantName: v.title ?? '',
                  oldPrice: v.beforePrice ?? v.price ?? 0,
                  newPrice: v.afterPrice ?? v.price ?? 0,
                  success: true,
                  beforePrice: v.beforePrice,
                  currentPrice: v.afterPrice ?? v.price ?? 0,
                ),
              ),
            )
            .toList(),
      ),
    );

    if (mounted) {
      setState(() => isLoading = false);
      showSnackbar(
          '✅ Update completed — Success: $success | ❌ Failed: $failed');
    }
  }

  // 🧩 --- UTILITIES ---

  void showSnackbar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        backgroundColor: kPrimary.withOpacity(0.95),
      ),
    );
  }

  bool _shopify_service_nullCheck() {
    if (_shopifyService == null) {
      showSnackbar('Connect to Shopify store first');
      return true;
    }
    return false;
  }

  Future<void> undoProduct(Product p) async {
    if (_shopifyService == null) {
      showSnackbar('Connect to Shopify store first');
      return;
    }
    if (p.variants.isEmpty) return;

    if (mounted) setState(() => isLoading = true);
    int restored = 0;
    int failed = 0;

    final futures =
        p.variants.where((v) => v.beforePrice != null).map((v) async {
      final oldPrice = v.beforePrice!;
      try {
        await _shopify_service_updateWrapper(
          productId: p.id.toString(),
          variantId: v.id.toString(),
          newPrice: oldPrice,
        );
        v.price = oldPrice;
        v.afterPrice = null;
        restored++;
      } catch (e) {
        debugPrint('Undo failed for ${v.id}: $e');
        failed++;
      }
    }).toList();

    await Future.wait(futures);

    if (mounted) setState(() => isLoading = false);
    showSnackbar(
        "Undo executed for '${p.title ?? ''}' — Restored: $restored | Failed: $failed");
  }

  Future<void> restoreProduct(Product p) async {
    if (_shopify_service_nullCheck()) return;
    if (p.variants.isEmpty) return;

    if (mounted) setState(() => isLoading = true);
    int restored = 0;
    int failed = 0;

    final futures =
        p.variants.where((v) => v.afterPrice != null).map((v) async {
      final targetPrice = v.afterPrice!;
      try {
        await _shopify_service_updateWrapper(
          productId: p.id.toString(),
          variantId: v.id.toString(),
          newPrice: targetPrice,
        );
        v.price = targetPrice;
        restored++;
      } catch (e) {
        debugPrint('Restore failed for ${v.id}: $e');
        failed++;
      }
    }).toList();

    await Future.wait(futures);

    if (mounted) setState(() => isLoading = false);
    showSnackbar(
        "Restore executed for '${p.title ?? ''}' — Restored: $restored | Failed: $failed");
  }

  Future<void> _shopify_service_updateWrapper({
    required String productId,
    required String variantId,
    required double newPrice,
    String? productName,
    String? variantName,
    double? oldPrice,
  }) async {
    if (_shopifyService == null) {
      throw Exception('Shopify service not initialized');
    }

    String resolvedProductName = productName ?? 'Unknown Product';
    String resolvedVariantName = variantName ?? 'Unknown Variant';
    double resolvedOldPrice = oldPrice ?? 0.0;

    try {
      final prod = allProducts.firstWhere(
        (p) => p.id.toString() == productId.toString(),
        orElse: () => Product.empty(),
      );

      if (prod.id != null) {
        resolvedProductName = productName ?? (prod.title ?? resolvedProductName);
        final variant = prod.variants.firstWhere(
          (vv) => vv.id.toString() == variantId.toString(),
          orElse: () =>
              prod.variants.isNotEmpty ? prod.variants.first : Variant.empty(),
        );

        if (variant.id != null) {
          resolvedVariantName =
              variantName ?? (variant.title ?? resolvedVariantName);
          resolvedOldPrice =
              oldPrice ?? (variant.beforePrice ?? variant.price ?? 0.0);
        }
      }
    } catch (e) {
      debugPrint('Could not resolve names/prices: $e');
    }

    final runId = "manual_${DateTime.now().millisecondsSinceEpoch}";
    final bool ok = await _shopifyService!.updateVariantPrice(
      productId: productId,
      variantId: variantId,
      productName: resolvedProductName,
      variantName: resolvedVariantName,
      oldPrice: resolvedOldPrice,
      newPrice: newPrice,
      runId: runId,
    );

    await DBService.savePriceUpdate(
      PriceUpdateLog(
        productId: productId,
        variantId: variantId,
        productName: resolvedProductName,
        variantName: resolvedVariantName,
        oldPrice: resolvedOldPrice,
        newPrice: newPrice,
        success: ok,
        timestamp: DateTime.now(),
        runId: runId,
      ),
    );

    await DBService.saveCurrentPrice(productId, variantId, newPrice);
  }

  // -------------------- UI SECTION --------------------

  @override
  Widget build(BuildContext context) {
    final progressText = (_total > 0 && isLoading)
        ? "Updating variants: $_processed / $_total"
        : null;

    final totalVariants = filteredProducts.fold<int>(
      0,
      (prev, p) => prev + p.variants.where((v) => v.price != null).length,
    );

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text(
          'Shopify Price Updater',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD7A4A4), Color.fromARGB(255, 215, 164, 164)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Analytics Dashboard',
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnalyticsDashboardScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Price update logs',
            icon: const Icon(Icons.history),
            onPressed: () {
              if (_shopifyService == null) {
                showSnackbar('Connect to Shopify store first');
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PriceUpdateLogScreen(
                    onPricesUpdated: () => setState(() {}),
                    allProducts: allProducts,
                    shopifyService: _shopifyService!,
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
              if (!mounted) return;
              if (result is Map<String, String>) {
                await connectAndFetch(result['domain'], result['token']);
              } else if (result is String) {
                updateCurrencySymbol(result);
              }
            },
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white.withOpacity(0.98),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Selected Products: ${filteredProducts.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  'Variants: $totalVariants',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ),

      body: isLoading && allProducts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildCategoryCard(),
                  const SizedBox(height: 16),
                  buildFiltersCard(),
                  const SizedBox(height: 16),
                  buildUpdateCard(),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      buildActionButton(
                        icon: Icons.price_change,
                        label: "Update Price",
                        onPressed: isLoading ? null : applyPriceUpdate,
                      ),
                      buildActionButton(
                        icon: Icons.list_alt,
                        label: "Products",
                        onPressed: isLoading
                            ? null
                            : () {
                                if (filteredProducts.isEmpty) {
                                  showSnackbar("No products to show");
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductListScreen(
                                      products: filteredProducts,
                                      currencyFormat: currencyFormat,
                                      onUndo: undoProduct,
                                      onRestore: restoreProduct,
                                      onPricesUpdated: () {},
                                    ),
                                  ),
                                );
                              },
                      ),
                    ],
                  ),
                  if (progressText != null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          progressText,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  // 🔹 Sub widgets (CategoryCard, FiltersCard, UpdateCard, ActionButton)
  Widget buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 150,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: kPrimary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(color: kText, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCategoryCard() {
    return Card(
      color: kCard,
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Category", style: _sectionTitle.copyWith(color: kText)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: selectedCategory,
              decoration: InputDecoration(
                filled: true,
                fillColor: kCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              hint: const Text("Select Category"),
              items: categories
                  .map((cat) =>
                      DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: isLoading
                  ? null
                  : (value) {
                      if (!mounted) return;
                      setState(() {
                        selectedCategory = value;
                        selectedSubcategory = null;
                        filterProducts();
                      });
                    },
            ),
            if (selectedCategory != null &&
                subcategories.containsKey(selectedCategory!) &&
                subcategories[selectedCategory!]!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text("Subcategory",
                  style: _labelStyle.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedSubcategory,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: kCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                hint: const Text("Select Subcategory"),
                items: subcategories[selectedCategory!]!
                    .map((sub) =>
                        DropdownMenuItem(value: sub, child: Text(sub)))
                    .toList(),
                onChanged: isLoading
                    ? null
                    : (value) {
                        if (!mounted) return;
                        setState(() {
                          selectedSubcategory = value;
                          filterProducts();
                        });
                      },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildFiltersCard() {
    return Card(
      color: kCard,
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Advanced Filters",
                style: _sectionTitle.copyWith(color: kText)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "RRP From",
                      labelStyle: _labelStyle,
                      filled: true,
                      fillColor: kCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (v) {
                      priceFrom = double.tryParse(v) ?? 0.0;
                      filterProducts();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "RRP To",
                      labelStyle: _labelStyle,
                      filled: true,
                      fillColor: kCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (v) {
                      priceTo = double.tryParse(v) ?? 1000000.0;
                      filterProducts();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: "Product Name",
                labelStyle: _labelStyle,
                filled: true,
                fillColor: kCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (v) {
                productNameFilter = v;
                filterProducts();
              },
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: "SKU",
                labelStyle: _labelStyle,
                filled: true,
                fillColor: kCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (v) {
                skuFilter = v;
                filterProducts();
              },
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "Round To (Dynamic)",
                labelStyle: _labelStyle,
                filled: true,
                fillColor: kCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (v) {
                dynamicRoundValue = double.tryParse(v) ?? 0;
                filterProducts();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildUpdateCard() {
    return Card(
      color: kCard,
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Update Type", style: _sectionTitle.copyWith(color: kText)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: operationType,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: kCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: ['Increase', 'Decrease']
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: isLoading
                        ? null
                        : (value) => setState(() {
                              operationType = value ?? operationType;
                            }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: valueType,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: kCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: ['Fixed', 'Percentage']
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: isLoading
                        ? null
                        : (value) => setState(() {
                              valueType = value ?? valueType;
                            }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              enabled: !isLoading,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: valueType == 'Fixed'
                    ? "Enter $currencySymbol Value"
                    : "Enter %",
                labelStyle: _labelStyle,
                filled: true,
                fillColor: kCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (v) => updateValue = double.tryParse(v) ?? 0.0,
            ),
          ],
        ),
      ),
    );
  }
}                                 




