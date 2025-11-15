import 'dart:developer';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ added
import '../models/update_log.dart';
import '../models/price_update_log.dart';

/// 🔹 Handles all local database (Hive) operations: logs, undo, cache, etc.
class DBService {
  static late Box<UpdateLogSummary> _updateLogBox;
  static late Box<PriceUpdateLog> _priceUpdateBox;
  static late Box<double> _currentPriceBox;

  // ---------------------------------------------------------------------------
  // 🔹 INITIALIZATION
  // ---------------------------------------------------------------------------

  static Future<void> initDB() async {
    final dir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(dir.path);

    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(PriceUpdateLogAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(UpdateLogSummaryAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(VariantDetailAdapter());

    _updateLogBox = await Hive.openBox<UpdateLogSummary>('update_logs');
    _priceUpdateBox = await Hive.openBox<PriceUpdateLog>('price_update_logs');
    _currentPriceBox = await Hive.openBox<double>('currentPricesBox');
  }

  // ---------------------------------------------------------------------------
  // 🔹 SUMMARY LOGS (Each update batch = 1 summary)
  // ---------------------------------------------------------------------------

  static Future<void> addSummaryLog(UpdateLogSummary logSummary) async {
    try {
      // ✅ Attach current store domain dynamically
      final prefs = await SharedPreferences.getInstance();
      final currentDomain = prefs.getString('shopDomain') ?? 'unknown_store';

      final updatedLog = UpdateLogSummary(
        category: logSummary.category,
        subCategory: logSummary.subCategory,
        operation: logSummary.operation,
        valueType: logSummary.valueType,
        value: logSummary.value,
        rounding: logSummary.rounding,
        total: logSummary.total,
        success: logSummary.success,
        failed: logSummary.failed,
        timestamp: logSummary.timestamp,
        runId: logSummary.runId,
        variantDetails: logSummary.variantDetails,
        storeDomain: currentDomain, // ✅ new field stored safely
      );

      await _updateLogBox.put(updatedLog.runId, updatedLog);
      log('✅ Saved Summary Log (${updatedLog.storeDomain}): ${updatedLog.runId}');
    } catch (e) {
      log('⚠️ addSummaryLog error: $e');
    }
  }

  static Future<void> saveUpdateLog(UpdateLogSummary logSummary) async {
    await addSummaryLog(logSummary);
  }

  static Future<List<UpdateLogSummary>> getSummaryLogs() async {
    final logs = _updateLogBox.values.toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    log("📦 Loaded ${logs.length} summary logs from Hive");
    return logs;
  }

  static Future<void> updateSummaryLogPrices(
      UpdateLogSummary logSummary, List<VariantDetail> variants) async {
    try {
      final updatedLog = UpdateLogSummary(
        category: logSummary.category,
        subCategory: logSummary.subCategory,
        operation: logSummary.operation,
        valueType: logSummary.valueType,
        value: logSummary.value,
        rounding: logSummary.rounding,
        total: logSummary.total,
        success: logSummary.success,
        failed: logSummary.failed,
        timestamp: logSummary.timestamp,
        runId: logSummary.runId,
        variantDetails: variants,
        storeDomain: logSummary.storeDomain, // ✅ retain store link
      );

      await _updateLogBox.put(logSummary.runId, updatedLog);
      log('✅ Updated summary log prices for ${logSummary.runId}');
    } catch (e) {
      log('⚠️ updateSummaryLogPrices error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 VARIANT PRICE LOGS (Per product variant)
  // ---------------------------------------------------------------------------

  static Future<void> savePriceLog({
    required String productId,
    required String variantId,
    required String productName,
    required String variantName,
    required double oldPrice,
    required double newPrice,
    required bool success,
    String? runId,
  }) async {
    try {
      // ✅ Get current connected store domain
      final prefs = await SharedPreferences.getInstance();
      final currentDomain = prefs.getString('shopDomain') ?? 'unknown_store';

      final entry = PriceUpdateLog(
        productId: productId,
        variantId: variantId,
        productName: productName,
        variantName: variantName,
        oldPrice: oldPrice,
        newPrice: newPrice,
        success: success,
        runId: runId ?? '',
        timestamp: DateTime.now(),
        storeDomain: currentDomain, // ✅ store domain added
      );

      await _priceUpdateBox.add(entry);
      log('💾 Saved Price Log → $productName ($variantName) [${entry.storeDomain}]: ₹$oldPrice → ₹$newPrice');
    } catch (e) {
      log('⚠️ savePriceLog error: $e');
    }
  }

  static Future<List<PriceUpdateLog>> getAllPriceLogs() async {
    final logs = _priceUpdateBox.values.toList().cast<PriceUpdateLog>();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  static Future<List<PriceUpdateLog>> getPriceLogsByRun(String runId) async {
    try {
      final allLogs = _priceUpdateBox.values.toList().cast<PriceUpdateLog>();
      return allLogs.where((log) => log.runId == runId).toList();
    } catch (e) {
      log('⚠️ getPriceLogsByRun error: $e');
      return [];
    }
  }

  static Future<void> savePriceUpdate(PriceUpdateLog logEntry) async {
    try {
      await _priceUpdateBox.add(logEntry);
      log('📝 Saved manual price update log → ${logEntry.productName} (${logEntry.variantName})');
    } catch (e) {
      log('⚠️ savePriceUpdate error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 PRICE STORAGE HELPERS (for live Shopify sync)
  // ---------------------------------------------------------------------------

  static Future<void> saveCurrentPrice(
      String productId, String variantId, double price) async {
    final key = '${productId}_$variantId';
    await _currentPriceBox.put(key, price);
    log('💾 Saved current Shopify price for $key → ₹$price');
  }

  static Future<double?> getCurrentPrice(
      String productId, String variantId) async {
    try {
      final key = '${productId}_$variantId';
      return _currentPriceBox.get(key);
    } catch (_) {
      return null;
    }
  }

  static Future<double?> getVariantOldPrice(
      String runId, String variantId) async {
    try {
      final logSummary = _updateLogBox.get(runId);
      if (logSummary == null) return null;
      final variant = logSummary.variantDetails.firstWhere(
        (v) => v.variantId == variantId,
        orElse: () => logSummary.variantDetails.first,
      );
      return variant.oldPrice;
    } catch (e) {
      log('⚠️ getVariantOldPrice error: $e');
      return null;
    }
  }

  static Future<double?> getVariantNewPrice(
      String runId, String variantId) async {
    try {
      final logSummary = _updateLogBox.get(runId);
      if (logSummary == null) return null;
      final variant = logSummary.variantDetails.firstWhere(
        (v) => v.variantId == variantId,
        orElse: () => logSummary.variantDetails.first,
      );
      return variant.newPrice;
    } catch (e) {
      log('⚠️ getVariantNewPrice error: $e');
      return null;
    }
  }

  static Future<double?> getBeforePrice(
      String productId, String variantId) async {
    try {
      final box = await Hive.openBox<double>('beforePriceBox');
      final key = '${productId}_$variantId';
      return box.get(key);
    } catch (e) {
      log('⚠️ getBeforePrice error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔹 UTILITIES
  // ---------------------------------------------------------------------------

  static Future<void> clearAllLogs() async {
    await _updateLogBox.clear();
    await _priceUpdateBox.clear();
    await _currentPriceBox.clear();
    log('🧹 All logs cleared');
  }

  static Future<void> close() async {
    if (_updateLogBox.isOpen) await _updateLogBox.close();
    if (_priceUpdateBox.isOpen) await _priceUpdateBox.close();
    if (_currentPriceBox.isOpen) await _currentPriceBox.close();
  }
}
