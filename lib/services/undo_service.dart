// 📄 UndoService.dart (✅ Final Redline-Free, No Hardcoding)
import 'package:flutter/foundation.dart';
import '../models/price_update_log.dart';
import '../services/db_services.dart';
import '../services/shopify_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UndoService {
  /// 🔄 Undo the last price update (revert all affected variants)
  static Future<Map<String, int>> undoLastUpdate() async {
    try {
      // ✅ Load stored Shopify credentials dynamically
      final prefs = await SharedPreferences.getInstance();
      final shopDomain = prefs.getString('shopDomain') ?? '';
      final accessToken = prefs.getString('accessToken') ?? '';

      if (shopDomain.isEmpty || accessToken.isEmpty) {
        debugPrint("❌ Missing Shopify credentials in SharedPreferences!");
        return {'restored': 0, 'failed': 0};
      }

      final shopifyService =
          ShopifyService(shopDomain: shopDomain, accessToken: accessToken);

      // ✅ Get all stored update summaries (each run = 1 batch update)
      final summaryLogs = await DBService.getSummaryLogs();

      if (summaryLogs.isEmpty) {
        debugPrint("⚠ No summary logs found.");
        return {'restored': 0, 'failed': 0};
      }

      // ✅ Get latest update run
      final lastLog = summaryLogs.last;
      final runId = lastLog.runId;

      // ✅ Fetch all price logs under that run
      final priceLogs = await DBService.getPriceLogsByRun(runId);
      if (priceLogs.isEmpty) {
        debugPrint("⚠ No detailed logs found for runId $runId");
        return {'restored': 0, 'failed': 0};
      }

      int restored = 0;
      int failed = 0;

      for (final log in priceLogs) {
        final productId = log.productId;
        final variantId = log.variantId;
        final oldPrice = log.oldPrice;
        final newPrice = log.newPrice;

        if (variantId.isEmpty || productId.isEmpty) {
          debugPrint("⚠ Skipping log: Missing IDs → ${log.productName}");
          failed++;
          continue;
        }

        try {
          // ✅ Revert the price in Shopify (no static call)
          final success =
              await shopifyService.updateVariantPriceDirect(variantId, oldPrice);

          if (success) {
            // ✅ Update local DB and save new undo log
            await DBService.saveCurrentPrice(productId, variantId, oldPrice);

            final undoLog = PriceUpdateLog(
              productId: productId,
              variantId: variantId,
              productName: log.productName,
              variantName: log.variantName,
              newPrice: newPrice,
              oldPrice: oldPrice,
              success: true,
              timestamp: DateTime.now(),
              runId: "UNDO_${DateTime.now().millisecondsSinceEpoch}",
            );

            await DBService.savePriceUpdate(undoLog);

            restored++;
            debugPrint(
                "↩ Undo Success: ${log.productName} — ₹$newPrice → ₹$oldPrice");
          } else {
            failed++;
            debugPrint("❌ Shopify revert failed: ${log.productName}");
          }
        } catch (e) {
          failed++;
          debugPrint("❌ Undo Exception for ${log.productName}: $e");
        }
      }

      debugPrint("✅ Undo Summary — Restored: $restored | Failed: $failed");
      return {'restored': restored, 'failed': failed};
    } catch (e) {
      debugPrint("❌ UndoService Global Error: $e");
      return {'restored': 0, 'failed': 0};
    }
  }
}





