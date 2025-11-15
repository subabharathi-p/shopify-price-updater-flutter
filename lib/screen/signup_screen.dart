import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/autologout_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  // ✅ Premium Soft Peach Theme
  static const Color kBg = Color(0xFFFDF6F2);
  static const Color kPrimary = Color(0xFFD7A4A4);
  static const Color kText = Color(0xFF333333);
  static const Color kCard = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    AutoLogoutService().startTimer(context);
  }

  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) return "Please enter your password";
    if (value.length < 6) return "Password must be at least 6 chars";
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).+$');
    if (!regex.hasMatch(value)) {
      return "Password must include:\n• 1 lowercase\n• 1 uppercase\n• 1 number\n• 1 special char";
    }
    return null;
  }

  InputDecoration getInputDecoration({
    required String label,
    required Icon prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: kPrimary, fontWeight: FontWeight.w500),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
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
        appBar: AppBar(
          backgroundColor: kBg,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ✅ Logo at top
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
                          "Sign Up",
                          style: TextStyle(
                            color: kText,
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Email
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
                        const SizedBox(height: 15),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: getInputDecoration(
                            label: "Password",
                            prefixIcon:
                                Icon(Icons.lock_outline, color: kPrimary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: kPrimary),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: passwordValidator,
                        ),
                        const SizedBox(height: 25),

                        // Sign Up Button
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
                                          .createUserWithEmailAndPassword(
                                        email: _emailController.text.trim(),
                                        password:
                                            _passwordController.text.trim(),
                                      );

                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              "Signup successful! Please login."),
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
                                          content:
                                              Text(e.message ?? "Signup failed"),
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
                                  "Sign Up",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 20),

                        // Back to Login
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}







