// ✅ lib/screen/settings_screen.dart — Final Fixed Version
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home_screen.dart';
import '../models/store.dart';
import '../services/store_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 🎨 Theme constants
  static const Color kBg = Color(0xFFF8EDEE);
  static const Color kPrimary = Color(0xFFD7A4A4);
  static const Color kCard = Color(0xFFFFFFFF);
  static const Color kText = Color(0xFF9B6C6C);
  static const double kRadius = 12;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _domainController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  String selectedCurrency = '₹';
  bool obscureToken = true;
  bool isLoading = false;

  final List<String> currencyOptions = ['₹', '\$', '€', '£', '¥'];

  @override
  void initState() {
    super.initState();
    loadStore();
  }

  // 🔹 Load saved store details
  Future<void> loadStore() async {
    try {
      final stores = await StoreService.getStores();
      if (stores.isNotEmpty) {
        final store = stores[0];
        _nameController.text = store.storeName;
        _domainController.text = store.shopDomain;
        _tokenController.text = store.accessToken;
        selectedCurrency = store.currency;

        // ⏳ small delay to ensure UI is ready before auto-fetch
        await Future.delayed(const Duration(milliseconds: 400));
        await autoFetchStore(store);
      } else {
        _nameController.clear();
        _domainController.clear();
        _tokenController.clear();
        selectedCurrency = '₹';
      }
      setState(() {});
    } catch (e) {
      debugPrint("⚠️ Error loading store: $e");
    }
  }

  // 🔹 Auto connect HomeScreen after loading
  Future<void> autoFetchStore(Store store) async {
    try {
      if (!mounted) return;
      if (store.shopDomain.isEmpty || store.accessToken.isEmpty) return;

      if (HomeScreen.globalKey.currentState != null) {
        await HomeScreen.globalKey.currentState!
            .connectAndFetch(store.shopDomain, store.accessToken);
        HomeScreen.globalKey.currentState!
            .updateCurrencySymbol(store.currency);

        if (mounted) {
          showSnack("✅ Store auto-connected successfully", Colors.green);
        }
      } else {
        debugPrint("⚠️ HomeScreen state not ready yet");
      }
    } catch (e) {
      debugPrint("⚠️ Auto fetch failed: $e");
    }
  }

  // 🔹 Save or update store credentials (Fixed Navigation)
  Future<void> saveStore() async {
    if (!_formKey.currentState!.validate()) return;

    final domainPattern = RegExp(r'^[a-zA-Z0-9\-]+\.myshopify\.com$');
    if (!domainPattern.hasMatch(_domainController.text.trim())) {
      showSnack("❌ Invalid Shopify domain format", Colors.red);
      return;
    }

    if (_tokenController.text.trim().length < 10) {
      showSnack("❌ Access token too short", Colors.red);
      return;
    }

    final newStore = Store(
      storeName: _nameController.text.trim(),
      shopDomain: _domainController.text.trim(),
      accessToken: _tokenController.text.trim(),
      currency: selectedCurrency,
    );

    setState(() => isLoading = true);

    try {
      final stores = await StoreService.getStores();
      if (stores.isNotEmpty) {
        await StoreService.updateStore(0, newStore);
      } else {
        await StoreService.addStore(newStore);
      }

      // Save credentials locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('shopDomain', newStore.shopDomain);
      await prefs.setString('accessToken', newStore.accessToken);
      await prefs.setString('currency', newStore.currency);
      await prefs.setBool('isShopifyVerified', true);

      showSnack("✅ Store saved successfully!", Colors.green.shade700);

      if (!mounted) return;

      // ⏳ wait for prefs to save fully
      await Future.delayed(const Duration(milliseconds: 400));

      // ✅ Relaunch HomeScreen to auto-fetch products
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            key: HomeScreen.globalKey,
            shopDomain: newStore.shopDomain,
            accessToken: newStore.accessToken,
          ),
        ),
      );
    } catch (e) {
      showSnack("❌ Save failed: $e", Colors.red.shade700);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // 🔹 Delete store and clear preferences
  Future<void> deleteStore() async {
    if (_domainController.text.isEmpty && _tokenController.text.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this store?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await StoreService.deleteStore(0);
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      _nameController.clear();
      _domainController.clear();
      _tokenController.clear();
      selectedCurrency = '₹';
      setState(() {});
      showSnack("✅ Store deleted", Colors.red.shade700);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            key: HomeScreen.globalKey,
            shopDomain: '',
            accessToken: '',
          ),
        ),
      );
    } catch (e) {
      showSnack("❌ Delete failed: $e", Colors.red.shade700);
    }
  }

  // 🔹 Reusable snack bar
  void showSnack(String message, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // 🔹 Input field style
  InputDecoration getInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: kText, fontWeight: FontWeight.w600),
      filled: true,
      fillColor: kCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadius),
        borderSide: const BorderSide(color: kPrimary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadius),
        borderSide: const BorderSide(color: kPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: getInputDecoration(label).copyWith(suffixIcon: suffix),
      validator: (v) => v == null || v.isEmpty ? "$label required" : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text(
          "Store Settings",
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 19, color: Colors.white),
        ),
        backgroundColor: kPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                buildTextField(controller: _nameController, label: "Store Name"),
                const SizedBox(height: 12),
                buildTextField(
                    controller: _domainController, label: "Shopify Domain"),
                const SizedBox(height: 12),
                buildTextField(
                  controller: _tokenController,
                  label: "Access Token",
                  obscure: obscureToken,
                  suffix: IconButton(
                    icon: Icon(
                      obscureToken ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => obscureToken = !obscureToken),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      "Currency: ",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, color: kText),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: selectedCurrency,
                      items: currencyOptions
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => selectedCurrency = v ?? '₹'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : saveStore,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: kPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kRadius),
                          ),
                          elevation: 3,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Save / Update",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: deleteStore,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kRadius),
                          ),
                          elevation: 3,
                        ),
                        child: const Text(
                          "Delete",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
