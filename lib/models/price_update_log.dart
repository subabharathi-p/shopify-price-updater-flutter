import 'package:hive/hive.dart';

part 'price_update_log.g.dart';

/// 🔹 Stores each product variant’s before/after price changes
@HiveType(typeId: 1)
class PriceUpdateLog extends HiveObject {
  @HiveField(0)
  final String productId;

  @HiveField(1)
  final String variantId;

  @HiveField(2)
  final String productName;

  @HiveField(3)
  final String variantName;

  /// 🪙 Price before update
  @HiveField(4)
  final double oldPrice;

  /// 💰 Price after update
  @HiveField(5)
  final double newPrice;

  /// ✅ Whether the update succeeded
  @HiveField(6)
  final bool success;

  /// 🕓 When the update happened
  @HiveField(7)
  final DateTime timestamp;

  /// 🆕 Unique run/session ID for grouping updates
  @HiveField(8)
  final String? runId;

  /// 🏷️ Type of update (e.g. Manual, Undo, Live)
  @HiveField(9)
  final String updateType;

  /// 🌐 Domain of the Shopify store where this update happened
  @HiveField(10)
  final String? storeDomain; // ✅ Added new field for multi-store support

  PriceUpdateLog({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.oldPrice,
    required this.newPrice,
    required this.success,
    required this.timestamp,
    this.runId,
    this.updateType = 'Manual',
    this.storeDomain, // ✅ Added here
  });

  /// 🧩 Safe fallback
  factory PriceUpdateLog.empty() => PriceUpdateLog(
        productId: '',
        variantId: '',
        productName: 'Unknown Product',
        variantName: 'Default Variant',
        oldPrice: 0.0,
        newPrice: 0.0,
        success: false,
        timestamp: DateTime.now(),
        runId: '',
        updateType: 'Manual',
        storeDomain: '', // ✅ Added default
      );

  /// 🧠 Convert to Map for JSON or CSV export
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'variantId': variantId,
      'productName': productName,
      'variantName': variantName,
      'oldPrice': oldPrice,
      'newPrice': newPrice,
      'success': success,
      'timestamp': timestamp.toIso8601String(),
      'runId': runId ?? '',
      'updateType': updateType,
      'storeDomain': storeDomain ?? '', // ✅ Added here too
    };
  }

  /// 🕓 For clean debugging/log printing
  @override
  String toString() =>
      '[$productName - $variantName] ₹$oldPrice → ₹$newPrice (${success ? "✅" : "❌"}) | Store: ${storeDomain ?? "N/A"}';
}
