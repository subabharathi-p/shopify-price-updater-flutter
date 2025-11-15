// 📄 StoreService.dart (Final Version for Multi-User Shopify)
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/store.dart';

class StoreService {
  static const String _activeStoreKey = 'active_store_id';

  /// 🔹 Get the current Firebase user ID
  static Future<String?> _getUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  /// 🔹 Unique key per user for saving store list
  static Future<String> _getKey() async {
    final uid = await _getUserId();
    if (uid == null) throw Exception("⚠️ User not logged in");
    return 'stores_$uid';
  }

  /// 🔹 Get all stored Shopify stores for this user
  static Future<List<Store>> getStores() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getKey();
    final data = prefs.getString(key);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => Store.fromMap(e)).toList();
  }

  /// 🔹 Save full list of stores
  static Future<void> saveStores(List<Store> stores) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getKey();
    final data = jsonEncode(stores.map((s) => s.toMap()).toList());
    await prefs.setString(key, data);
  }

  /// 🔹 Add a new store
  static Future<void> addStore(Store store) async {
    final stores = await getStores();
    stores.add(store);
    await saveStores(stores);
  }

  /// 🔹 Update existing store
  static Future<void> updateStore(int index, Store store) async {
    final stores = await getStores();
    if (index >= 0 && index < stores.length) {
      stores[index] = store;
      await saveStores(stores);
    }
  }

  /// 🔹 Delete store by index
  static Future<void> deleteStore(int index) async {
    final stores = await getStores();
    if (index >= 0 && index < stores.length) {
      stores.removeAt(index);
      await saveStores(stores);
    }
  }

  /// 🔹 Set active store (so ShopifyService knows which one to use)
  static Future<void> setActiveStore(Store store) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeStoreKey, jsonEncode(store.toMap()));
  }

  /// 🔹 Get currently active store
  static Future<Store?> getStoreDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_activeStoreKey);
    if (data == null) return null;
    return Store.fromMap(jsonDecode(data));
  }

  /// 🔹 Clear active store (on logout, etc.)
  static Future<void> clearActiveStore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeStoreKey);
  }
}

