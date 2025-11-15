import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/store.dart';
import '../services/store_service.dart';

class RestoreService {
  /// ✅ Restore the last active store for the logged-in user
  static Future<Store?> restoreLastStore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('⚠️ No logged-in user found during restore.');
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastStoreKey = 'last_store_${user.uid}';

      final lastStoreName = prefs.getString(lastStoreKey);
      if (lastStoreName == null || lastStoreName.isEmpty) {
        print('ℹ️ No previous store found for this user.');
        return null;
      }

      final allStores = await StoreService.getStores();
      if (allStores.isEmpty) {
        print('⚠️ No saved stores found for user.');
        return null;
      }

      final store = allStores.firstWhere(
        (s) => s.storeName == lastStoreName,
        orElse: () => allStores.first,
      );

      print('✅ Restored store: ${store.storeName}');
      await StoreService.setActiveStore(store);
      return store;
    } catch (e) {
      print('❌ Error restoring last store: $e');
      return null;
    }
  }

  /// 💾 Save the last used store for the next app launch
  static Future<void> saveLastUsedStore(Store store) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('⚠️ No logged-in user found during save.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastStoreKey = 'last_store_${user.uid}';
      await prefs.setString(lastStoreKey, store.storeName);

      print('💾 Last used store saved: ${store.storeName}');
    } catch (e) {
      print('❌ Error saving last used store: $e');
    }
  }

  /// 🧹 Clear restore data (optional, during logout)
  static Future<void> clearRestoreData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final lastStoreKey = 'last_store_${user.uid}';
      await prefs.remove(lastStoreKey);

      print('🧹 Restore data cleared for user: ${user.uid}');
    } catch (e) {
      print('❌ Error clearing restore data: $e');
    }
  }
}
