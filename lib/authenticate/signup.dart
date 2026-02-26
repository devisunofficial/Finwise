import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _obscurePassword = true;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  double passwordStrength = 0;
  bool emailSent = false;
  Timer? verificationTimer;

  // ---------------- PASSWORD STRENGTH ----------------
  void _checkPasswordStrength(String value) {
    double strength = 0;
    if (value.length >= 6) strength += 0.3;
    if (RegExp(r'[A-Z]').hasMatch(value)) strength += 0.2;
    if (RegExp(r'[0-9]').hasMatch(value)) strength += 0.2;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      strength += 0.3;
    }

    setState(() {
      passwordStrength = strength.clamp(0, 1);
    });
  }

  // ---------------- SIGN UP ----------------
  Future<void> signUp() async {
    setState(() => isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      await userCredential.user!.sendEmailVerification();
      emailSent = true;

      startVerificationCheck();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Signup failed")));
    }

    setState(() => isLoading = false);
  }

  // ---------------- VERIFY CHECK ----------------
  void startVerificationCheck() {
    verificationTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      User user = FirebaseAuth.instance.currentUser!;
      await user.reload();
      user = FirebaseAuth.instance.currentUser!;

      if (user.emailVerified) {
        verificationTimer?.cancel();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, "/login");
      }
    });
  }

  // ---------------- RESEND ----------------
  Future<void> resendVerification() async {
    await FirebaseAuth.instance.currentUser!.sendEmailVerification();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Verification email resent")));
  }

  @override
  void dispose() {
    verificationTimer?.cancel();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: emailSent ? verificationUI() : signUpUI(),
        ),
      ),
    );
  }

  // ---------------- SIGNUP UI ----------------
  Widget signUpUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        const Text(
          "Create account",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A1A33),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Sign up to start managing your finances",
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 32),

        // Email
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: inputDecoration("Email address"),
        ),
        const SizedBox(height: 20),

        // Password
        TextField(
          controller: passwordController,
          obscureText: _obscurePassword,
          onChanged: _checkPasswordStrength,
          decoration: inputDecoration("Password").copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Strength Bar
        LinearProgressIndicator(
          value: passwordStrength,
          backgroundColor: Colors.grey.shade300,
          color: passwordStrength > 0.7
              ? Colors.green
              : passwordStrength > 0.4
              ? Colors.orange
              : Colors.red,
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: passwordStrength < 0.6 || isLoading ? null : signUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A1A33),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Sign up"),
          ),
        ),
      ],
    );
  }

  // ---------------- VERIFY UI ----------------
  Widget verificationUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.email_outlined, size: 64),
        const SizedBox(height: 16),
        const Text(
          "Verify your email",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "A verification link has been sent to your email.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: resendVerification,
          child: const Text("Resend email"),
        ),
        const SizedBox(height: 12),

        const Text(
          "Waiting for verification...",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  // ---------------- DECORATION ----------------
  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
