// 📄 product.dart (Final Full Working Version ✅ No Red Lines Anywhere)
class Product {
  final String id;
  final String title;
  final String productType;
  final String? subcategory;
  final String? tags;
  final List<Variant> variants;

  double price;
  DateTime? lastUpdated;

  Product({
    required this.id,
    required this.title,
    required this.productType,
    this.subcategory,
    this.tags,
    required this.variants,
    this.price = 0.0,
    this.lastUpdated,
  });

  /// 🔹 Create from Shopify JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    String? extractedSubcategory;

    if (json['tags'] != null && json['tags'].toString().isNotEmpty) {
      extractedSubcategory = json['tags'].toString().split(',').first.trim();
    } else if (json['vendor'] != null && json['vendor'].toString().isNotEmpty) {
      extractedSubcategory = json['vendor'].toString().trim();
    }

    List<Variant> variantsList = [];
    double productPrice = 0.0;

    if (json['variants'] != null && (json['variants'] as List).isNotEmpty) {
      variantsList = (json['variants'] as List)
          .map((v) => Variant.fromJson(v))
          .toList();
      productPrice = variantsList[0].price;
    }

    return Product(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      productType: json['product_type'] ?? '',
      subcategory: extractedSubcategory,
      tags: json['tags']?.toString(),
      variants: variantsList,
      price: productPrice,
      lastUpdated: null,
    );
  }

  /// 🔹 Empty factory to avoid null errors
  factory Product.empty() {
    return Product(
      id: '',
      title: '',
      productType: '',
      subcategory: '',
      tags: '',
      variants: [],
      price: 0.0,
      lastUpdated: null,
    );
  }

  /// 🔹 Deep copy
  Product copy() {
    return Product(
      id: id,
      title: title,
      productType: productType,
      subcategory: subcategory,
      tags: tags,
      variants: variants.map((v) => v.copy()).toList(),
      price: price,
      lastUpdated: lastUpdated,
    );
  }
}

class Variant {
  final String id;
  final String title;
  final String? sku;
  double price;

  double? beforePrice;
  double? afterPrice;
  double? currentPrice;

  Variant({
    required this.id,
    required this.title,
    required this.price,
    this.sku,
    this.beforePrice,
    this.afterPrice,
    this.currentPrice,
  });

  /// 🔹 Create from JSON
  factory Variant.fromJson(Map<String, dynamic> json) {
    double parsedPrice = double.tryParse(json['price'].toString()) ?? 0.0;
    String variantId =
        json['id']?.toString() ?? DateTime.now().toIso8601String();

    return Variant(
      id: variantId,
      title: json['title'] ?? '',
      price: parsedPrice,
      sku: json['sku']?.toString(),
      beforePrice: parsedPrice,
      currentPrice: parsedPrice,
    );
  }

  /// 🔹 Empty factory to avoid null errors
  factory Variant.empty() {
    return Variant(
      id: '',
      title: '',
      price: 0.0,
      sku: '',
      beforePrice: 0.0,
      afterPrice: 0.0,
      currentPrice: 0.0,
    );
  }

  /// 🔹 Set after price
  void setAfterPrice(double newPrice) {
    afterPrice = newPrice;
  }

  /// 🔹 Apply price update
  void applyPrice(double newPrice) {
    beforePrice = price;
    price = newPrice;
    afterPrice = newPrice;
    currentPrice = newPrice;
  }

  /// 🔹 Restore old price
  void restorePrice() {
    if (beforePrice != null) {
      price = beforePrice!;
      afterPrice = null;
      currentPrice = price;
    }
  }

  /// 🔹 Deep copy
  Variant copy() {
    return Variant(
      id: id,
      title: title,
      price: price,
      sku: sku,
      beforePrice: beforePrice,
      afterPrice: afterPrice,
      currentPrice: currentPrice,
    );
  }
}




