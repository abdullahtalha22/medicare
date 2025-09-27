import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    _autoLoginIfRemembered();
  }

  // Auto-login if "Remember Me" was checked
  Future<void> _autoLoginIfRemembered() async {
    try {
      final remember = await _secureStorage.read(key: 'remember');
      if (remember == 'true') {
        final savedEmail = await _secureStorage.read(key: 'email');
        final savedPassword = await _secureStorage.read(key: 'password');

        if (savedEmail != null && savedPassword != null) {
          setState(() {
            _emailController.text = savedEmail;
            _passwordController.text = savedPassword;
            _rememberMe = true;
            _isLoading = true;
          });

          await _auth.signInWithEmailAndPassword(
            email: savedEmail,
            password: savedPassword,
          );

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        }
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  // Save or clear credentials
  Future<void> _saveOrClearCredentials() async {
    if (_rememberMe) {
      await _secureStorage.write(key: 'remember', value: 'true');
      await _secureStorage.write(key: 'email', value: _emailController.text.trim());
      await _secureStorage.write(key: 'password', value: _passwordController.text);
    } else {
      await _secureStorage.delete(key: 'remember');
      await _secureStorage.delete(key: 'email');
      await _secureStorage.delete(key: 'password');
    }
  }

  // Email/Password login
  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _saveOrClearCredentials();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login Successful")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "Login failed. Please try again.";
      if (e.code == 'user-not-found') message = "No user found for this email.";
      else if (e.code == 'wrong-password') message = "Incorrect password.";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Google login
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final userDoc = FirebaseFirestore.instance.collection("users").doc(user.uid);
        final snapshot = await userDoc.get();

        if (!snapshot.exists) {
          await userDoc.set({
            "name": user.displayName ?? "",
            "phone": "",
            "address": "",
            "email": user.email ?? "",
            "createdAt": FieldValue.serverTimestamp(),
          });
        }

        if (_rememberMe) {
          await _secureStorage.write(key: 'remember', value: 'true');
          await _secureStorage.write(key: 'email', value: user.email ?? '');
          await _secureStorage.delete(key: 'password');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Google Sign-In successful")),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } on MissingPluginException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Google Sign-In plugin not registered. Run:\nflutter clean && flutter pub get && flutter run",
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In failed: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF007AFF), Color(0xFF28C76F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Welcome Back 👋",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Login to continue your journey",
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 40),
                  // Email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "Email Address",
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.email, color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Password
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "Password",
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.lock, color: Colors.black),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.black,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Remember + Forgot
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) => setState(() => _rememberMe = value ?? false),
                        checkColor: Colors.white,
                        activeColor: const Color(0xFF28C76F),
                      ),
                      const Text("Remember me", style: TextStyle(color: Colors.white)),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                          );
                        },
                        child: const Text("Forgot Password?", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF28C76F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.green)
                          : const Text("Login", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Google Lottie
                  GestureDetector(
                    onTap: _isLoading ? null : _loginWithGoogle,
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: Lottie.asset(
                        'assets/animations/google.json',
                        repeat: true,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  // Sign up redirect
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don’t have an account?", style: TextStyle(color: Colors.white)),
                      TextButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const SignupScreen()),
                        ),
                        child: const Text("Sign Up", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
