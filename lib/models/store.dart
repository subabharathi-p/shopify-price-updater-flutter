import 'package:hive/hive.dart';

part 'store.g.dart';

@HiveType(typeId: 0)
class Store extends HiveObject {
  @HiveField(0)
  final String storeName;

  @HiveField(1)
  final String shopDomain;

  @HiveField(2)
  final String accessToken;

  @HiveField(3)
  final String currency;

  Store({
    required this.storeName,
    required this.shopDomain,
    required this.accessToken,
    required this.currency,
  });

  factory Store.fromMap(Map<String, dynamic> map) {
    return Store(
      storeName: map['storeName'] ?? '',
      shopDomain: map['shopDomain'] ?? '',
      accessToken: map['accessToken'] ?? '',
      currency: map['currency'] ?? '₹',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storeName': storeName,
      'shopDomain': shopDomain,
      'accessToken': accessToken,
      'currency': currency,
    };
  }
}
