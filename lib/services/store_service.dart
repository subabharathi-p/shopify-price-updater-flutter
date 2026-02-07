import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/store.dart';

class StoreService {
  static const String _storeKey = 'local_store';
  static const String _activeStoreKey = 'active_store';

  /// 🔹 Get stored Shopify store (single-store app)
  static Future<List<Store>> getStores() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storeKey);
    if (data == null) return [];
    final map = jsonDecode(data);
    return [Store.fromMap(map)];
  }

  /// 🔹 Add store (overwrite – single store)
  static Future<void> addStore(Store store) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeKey, jsonEncode(store.toMap()));
  }

  /// 🔹 Update store
  static Future<void> updateStore(int index, Store store) async {
    await addStore(store);
  }

  /// 🔹 Delete store
  static Future<void> deleteStore(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storeKey);
    await prefs.remove(_activeStoreKey);
  }

  /// 🔹 Set active store
  static Future<void> setActiveStore(Store store) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _activeStoreKey,
      jsonEncode(store.toMap()),
    );
  }

  /// 🔹 Get active store
  static Future<Store?> getStoreDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_activeStoreKey);
    if (data == null) return null;
    return Store.fromMap(jsonDecode(data));
  }

  /// 🔹 Clear active store
  static Future<void> clearActiveStore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeStoreKey);
  }
}


