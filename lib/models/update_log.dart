import 'package:hive/hive.dart';
import '../services/db_services.dart';

part 'update_log.g.dart';

/// 🔹 Each product variant's before/after price details
@HiveType(typeId: 3)
class VariantDetail {
  @HiveField(0)
  final String variantId;

  @HiveField(1)
  final String productId;

  @HiveField(2)
  final String productName;

  @HiveField(3)
  final String variantName;

  @HiveField(4)
  double oldPrice;

  @HiveField(5)
  double newPrice;

  @HiveField(6)
  bool success;

  @HiveField(7)
  double? beforePrice; // Used for undo

  @HiveField(8)
  double currentPrice; // Current Shopify price

  VariantDetail({
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.oldPrice,
    required this.newPrice,
    required this.success,
    this.beforePrice,
    this.currentPrice = 0.0,
  });

  /// 🧩 Helper to copy & update safely
  VariantDetail copyWith({
    double? oldPrice,
    double? newPrice,
    bool? success,
    double? beforePrice,
    double? currentPrice,
  }) {
    return VariantDetail(
      variantId: variantId,
      productId: productId,
      productName: productName,
      variantName: variantName,
      oldPrice: oldPrice ?? this.oldPrice,
      newPrice: newPrice ?? this.newPrice,
      success: success ?? this.success,
      beforePrice: beforePrice ?? this.beforePrice,
      currentPrice: currentPrice ?? this.currentPrice,
    );
  }
}

/// 🔹 Summary of one update operation (e.g. Rings → +10%)
@HiveType(typeId: 2)
class UpdateLogSummary extends HiveObject {
  @HiveField(0)
  final String runId;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final String? subCategory;

  @HiveField(4)
  final String operation; // Increase / Decrease / Restore

  @HiveField(5)
  final String valueType; // Fixed / Percentage

  @HiveField(6)
  final double value;

  @HiveField(7)
  final String rounding; // 49, 99, None

  @HiveField(8)
  final int total;

  @HiveField(9)
  int success;

  @HiveField(10)
  int failed;

  @HiveField(11)
  final String type; // "UPDATE" / "RESTORE"

  @HiveField(12)
  List<VariantDetail> variantDetails;

  @HiveField(13)
  DateTime lastUpdated;

  @HiveField(14)
  String? storeDomain; // ✅ Added new field (multi-store support)

  UpdateLogSummary({
    required this.runId,
    required this.timestamp,
    required this.category,
    this.subCategory,
    required this.operation,
    required this.valueType,
    required this.value,
    required this.rounding,
    required this.total,
    required this.success,
    required this.failed,
    this.type = "UPDATE",
    DateTime? lastUpdated,
    List<VariantDetail>? variantDetails,
    this.storeDomain, // ✅ new field in constructor
  })  : variantDetails = variantDetails ?? [],
        lastUpdated = lastUpdated ?? DateTime.now();

  /// 🧩 Migration helper for older saved Hive logs
  factory UpdateLogSummary.migrate(UpdateLogSummary oldLog) {
    return UpdateLogSummary(
      runId: oldLog.runId,
      timestamp: oldLog.timestamp,
      category: oldLog.category,
      subCategory: oldLog.subCategory,
      operation: oldLog.operation,
      valueType: oldLog.valueType,
      value: oldLog.value,
      rounding: oldLog.rounding,
      total: oldLog.total,
      success: oldLog.success,
      failed: oldLog.failed,
      lastUpdated: oldLog.lastUpdated,
      type: oldLog.type,
      variantDetails: oldLog.variantDetails,
      storeDomain: oldLog.storeDomain, // ✅ Keep domain info during migration
    );
  }

  /// 🧾 Ensures variant details have valid before/current prices from local DB
  Future<void> ensureVariantDetails() async {
    for (var v in variantDetails) {
      v.beforePrice ??=
          await DBService.getBeforePrice(v.productId, v.variantId) ?? v.oldPrice;

      v.currentPrice =
          await DBService.getCurrentPrice(v.productId, v.variantId) ?? v.newPrice;

      if (v.currentPrice == 0.0) {
        v.currentPrice = v.newPrice;
      }
    }
  }

  @override
  String toString() =>
      '[$category → $operation $valueType $value] $total items | RunID: $runId | Store: ${storeDomain ?? "N/A"}';
}
