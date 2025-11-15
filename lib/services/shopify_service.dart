// lib/services/shopify_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ Added
import '../product.dart';
import '../models/update_log.dart';
import '../services/db_services.dart';

class ShopifyService {
  final String shopDomain;
  final String accessToken;

  ShopifyService({required this.shopDomain, required this.accessToken});

  // ==========================================================
  // 🔹 FETCH PRODUCTS
  // ==========================================================
  Future<List<Product>> fetchProducts() async {
    List<Product> allProducts = [];
    String? nextPageInfo;

    do {
      final url =
          'https://$shopDomain/admin/api/2024-04/products.json?limit=250${nextPageInfo != null ? "&page_info=$nextPageInfo" : ""}';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Shopify-Access-Token': accessToken,
        },
      );

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        final List productsJson = jsonBody['products'];

        for (var p in productsJson) {
          allProducts.add(Product.fromJson(p));
        }

        // 🔹 Handle pagination
        if (response.headers.containsKey('link')) {
          final linkHeader = response.headers['link']!;
          final match = RegExp(r'<([^>]+)>;\s*rel="next"').firstMatch(linkHeader);
          if (match != null) {
            final nextUrl = match.group(1)!;
            final uri = Uri.parse(nextUrl);
            nextPageInfo = uri.queryParameters['page_info'];
          } else {
            nextPageInfo = null;
          }
        } else {
          nextPageInfo = null;
        }
      } else {
        debugPrint('❌ Fetch failed: ${response.statusCode} ${response.body}');
        throw Exception('Failed to fetch products: ${response.body}');
      }
    } while (nextPageInfo != null);

    debugPrint("✅ Total fetched products: ${allProducts.length}");
    return allProducts;
  }

  // ==========================================================
  // 🔹 UPDATE VARIANT PRICE (and save logs)
  // ==========================================================
  Future<bool> updateVariantPrice({
    required String productId,
    required String variantId,
    required String productName,
    required String variantName,
    required double oldPrice,
    required double newPrice,
    required String runId,
  }) async {
    final url =
        'https://$shopDomain/admin/api/2024-04/variants/$variantId.json';
    final body = jsonEncode({
      "variant": {"id": variantId, "price": newPrice.toStringAsFixed(2)}
    });

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Shopify-Access-Token': accessToken,
        },
        body: body,
      );

      bool success = response.statusCode == 200;

      if (success) {
        debugPrint('✅ Updated variant $variantId → ₹$newPrice');

        // ✅ Save per-variant log safely
        await DBService.savePriceLog(
          productId: productId,
          variantId: variantId,
          productName: productName,
          variantName: variantName,
          oldPrice: oldPrice,
          newPrice: newPrice,
          success: true,
          runId: runId,
        );
      } else {
        debugPrint(
            '❌ Failed to update variant $variantId: ${response.statusCode} | ${response.body}');
        await DBService.savePriceLog(
          productId: productId,
          variantId: variantId,
          productName: productName,
          variantName: variantName,
          oldPrice: oldPrice,
          newPrice: newPrice,
          success: false,
          runId: runId,
        );
      }

      return success;
    } catch (e) {
      debugPrint('⚠️ Error updating variant $variantId: $e');

      // 🔹 Save failed attempt too
      await DBService.savePriceLog(
        productId: productId,
        variantId: variantId,
        productName: productName,
        variantName: variantName,
        oldPrice: oldPrice,
        newPrice: newPrice,
        success: false,
        runId: runId,
      );

      return false;
    }
  }

  // ==========================================================
  // 🔹 FETCH PRODUCT BY ID
  // ==========================================================
  Future<Product?> fetchProductById(String productId) async {
    final url = 'https://$shopDomain/admin/api/2024-04/products/$productId.json';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Shopify-Access-Token': accessToken,
        },
      );

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        return Product.fromJson(jsonBody['product']);
      } else {
        debugPrint('Failed to fetch product $productId: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching product $productId: $e');
      return null;
    }
  }

  // ==========================================================
  // 🔹 GET VARIANT DETAILS
  // ==========================================================
  Future<Map<String, dynamic>?> getVariant(String variantId) async {
    final url =
        'https://$shopDomain/admin/api/2024-04/variants/$variantId.json';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Shopify-Access-Token': accessToken,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Variant fetch failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching variant: $e');
      return null;
    }
  }

  // ==========================================================
  // 🔹 UNDO / RESTORE SUPPORT
  // ==========================================================
  Future<bool> updateVariantPriceDirect(String variantId, double oldPrice) async {
    final url =
        'https://$shopDomain/admin/api/2024-04/variants/$variantId.json';
    final body = jsonEncode({
      "variant": {"id": variantId, "price": oldPrice.toStringAsFixed(2)}
    });

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Shopify-Access-Token': accessToken,
        },
        body: body,
      );

      if (response.statusCode == 200) {
        debugPrint('♻️ Undo successful for variant $variantId → ₹$oldPrice');
        return true;
      } else {
        debugPrint(
            '❌ Undo failed for $variantId: ${response.statusCode} | ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ Undo error for variant $variantId: $e');
      return false;
    }
  }

  // ==========================================================
  // 🔹 GET LATEST VARIANT PRICE
  // ==========================================================
  Future<double?> getVariantPrice(String variantId) async {
    final url =
        'https://$shopDomain/admin/api/2024-04/variants/$variantId.json';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Shopify-Access-Token': accessToken,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return double.tryParse(data['variant']['price']);
      } else {
        debugPrint('❌ getVariantPrice failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('⚠️ Error getting variant price: $e');
      return null;
    }
  }

  // ==========================================================
  // 🔹 HELPER TO GET CURRENT STORE
  // ==========================================================
  static Future<String> getCurrentStoreDomain() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('shopDomain') ?? 'unknown_store';
  }
}
