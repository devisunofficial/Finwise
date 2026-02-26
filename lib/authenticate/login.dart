import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'signup.dart';
import 'auth.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // void _login() {
  //   String email = emailController.text;
  //   String password = passwordController.text;

  //   // For now, just print values
  //   debugPrint('Email: $email');
  //   debugPrint('Password: $password');
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              const Text(
                "Welcome back",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                "Sign in to continue managing your finances",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 32),

              // Email field
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: "Email address",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: "Password",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Sign in button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B1C3D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final email = emailController.text.trim();
                    final password = passwordController.text.trim();
                    final messenger = ScaffoldMessenger.of(context);

                    try {
                      await _authService.signInWithEmailAndPassword(
                        email: email,
                        password: password,
                      );
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text('Sign in failed: $e')),
                      );
                    }
                  },
                  child: const Text("Sign in", style: TextStyle(fontSize: 16)),
                ),
              ),

              const SizedBox(height: 16),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    debugPrint("Google Sign-In Clicked");
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Continue with",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Google Logo instead of "Google" text
                      SvgPicture.asset('assets/icons/google.svg', height: 20),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Sign up link
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpPage(),
                      ),
                    );
                  },
                  child: const Text(
                    "Don’t have an account? Sign Up",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0B1C3D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
