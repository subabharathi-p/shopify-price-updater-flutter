import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart'; // 👈 added for elegant font
import 'package:shopify_pricesync_v2/home_screen.dart';
import 'package:shopify_pricesync_v2/screen/login_screen.dart';
import 'package:shopify_pricesync_v2/screen/settings_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color kBgStart = Color(0xFFFDF6EC);
  static const Color kBgEnd = Color(0xFFF8EDEE);
  static const Color kPrimary = Color(0xFFD7A4A4);

  @override
  void initState() {
    super.initState();
    navigateNext();
  }

  Future<void> navigateNext() async {
    await Future.delayed(const Duration(seconds: 5));

    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final isShopifyVerified = prefs.getBool('isShopifyVerified') ?? false;
    final savedDomain = prefs.getString('shopDomain');

    if (!mounted) return;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else if (!isShopifyVerified || savedDomain == null || savedDomain.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            shopDomain: savedDomain,
            accessToken: '',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 🌸 Background gradient (unchanged)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kBgStart, kBgEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ✨ Soft glowing background circles
          Positioned(
            top: size.height * 0.2,
            left: size.width * 0.15,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.25),
                    blurRadius: 90,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.2,
            right: size.width * 0.1,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.18),
                    blurRadius: 110,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // 💎 Main visible content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🪞 Logo with border + soft glow
              Container(
                width: size.width * 0.30,
                height: size.width * 0.30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: kPrimary.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                  ],
                  image: const DecorationImage(
                    image: AssetImage("assets/ijc_logo.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // 🏷 Brand name — Elegant logo-style text
              Text(
                "INDEPENDENT\nJEWELLERS\nCOLLECTIVE",
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzel(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                  height: 1.2,
                  color: const Color(0xFF5E3D3D),
                  shadows: const [
                    Shadow(
                      color: Colors.white,
                      offset: Offset(0, 1),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              const Text(
                "Shopify Price Updater",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9B6C6C),
                  letterSpacing: 0.9,
                  shadows: [
                    Shadow(
                      color: Colors.white,
                      offset: Offset(0, 0),
                      blurRadius: 4,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              // ✨ Tagline
              const Text(
                "Empowering Jewellers with Smart Pricing",
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF9B6C6C),
                  letterSpacing: 0.7,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 35),

              // 🔄 Progress bar
              Container(
                width: size.width * 0.55,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  child: LinearProgressIndicator(
                    color: kPrimary,
                    backgroundColor: Colors.transparent,
                    minHeight: 5,
                  ),
                ),
              ),
            ],
          ),

          // 📜 Footer
          Positioned(
            bottom: 25,
            child: Text(
              "© 2025 Independent Jewellers Collective",
              style: TextStyle(
                fontSize: 11,
                color: Colors.black.withOpacity(0.45),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

