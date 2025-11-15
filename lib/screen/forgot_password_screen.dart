import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/autologout_service.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // ✅ Consistent Soft Peach Premium Theme
  static const Color kBg = Color(0xFFFDF6F2);
  static const Color kPrimary = Color(0xFFD7A4A4);
  static const Color kText = Color(0xFF333333);
  static const Color kCard = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    AutoLogoutService().startTimer(context);
  }

  InputDecoration getInputDecoration({
    required String label,
    required Icon prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: kPrimary, fontWeight: FontWeight.w500),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: kCard,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: kPrimary.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: kPrimary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => AutoLogoutService().userActivityDetected(context),
      onPanDown: (_) => AutoLogoutService().userActivityDetected(context),
      child: Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                color: kCard,
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Back button icon
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: kPrimary, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // IJC Logo - Updated height 100 for consistency
                            SizedBox(
                              height: 100,
                              child: Image.asset(
                                'assets/ijc_logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Heading
                            Text(
                              "Forgot Password",
                              style: TextStyle(
                                color: kText,
                                fontWeight: FontWeight.bold,
                                fontSize: 26,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Enter your email to receive a password reset link",
                              style: TextStyle(
                                color: kText.withOpacity(0.7),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 25),

                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: getInputDecoration(
                                label: "Email",
                                prefixIcon:
                                    Icon(Icons.email_outlined, color: kPrimary),
                              ),
                              validator: (value) =>
                                  value!.isEmpty ? "Please enter your email" : null,
                            ),
                            const SizedBox(height: 25),

                            // Send Reset Link Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                                elevation: 4,
                              ),
                              onPressed: _loading
                                  ? null
                                  : () async {
                                      if (_formKey.currentState!.validate()) {
                                        setState(() => _loading = true);
                                        try {
                                          await FirebaseAuth.instance
                                              .sendPasswordResetEmail(
                                                  email:
                                                      _emailController.text.trim());

                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  "Password reset link sent! Check inbox or Spam folder."),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const LoginScreen()),
                                          );
                                        } on FirebaseAuthException catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  e.message ?? "Failed to send link"),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        } finally {
                                          if (mounted) setState(() => _loading = false);
                                        }
                                      }
                                    },
                              child: _loading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      "Send Reset Link",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 20),

                            // Back to Login Button
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                "Back to Login",
                                style: TextStyle(
                                  color: kPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

