import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../onboarding/onboarding_step1.dart';

class EmailSignupScreen extends StatefulWidget {
  const EmailSignupScreen({super.key});

  @override
  State<EmailSignupScreen> createState() => _EmailSignupScreenState();
}

class _EmailSignupScreenState extends State<EmailSignupScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  String? _errorMessage;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _confirmObscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
      _loading = true;
    });

    try {
      await _authService.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passController.text.trim(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_new_signup_user', true);
      await prefs.setBool('seen_onboarding', false); // ensure onboarding shown

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OnboardingStep1()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = "An unexpected error occurred.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _decor(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.transparent),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.transparent),
      borderRadius: BorderRadius.circular(12),
    ),
    fillColor: Colors.grey[900],
    filled: true,
  );

  Widget _buildInput(
      String label,
      IconData icon,
      TextEditingController controller, {
        bool isPassword = false,
        bool obscureText = false,
        VoidCallback? toggleObscure,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(color: Colors.white54),
        decoration: _decor(label).copyWith(
          prefixIcon: Icon(icon, color: Colors.white70),
          contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              obscureText ? Icons.visibility : Icons.visibility_off,
              color: Colors.white54,
            ),
            onPressed: toggleObscure,
          )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _ = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackButton(color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                "Create your\nAccount",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 30),
              _buildInput(
                "Email",
                Icons.email,
                _emailController,
                validator: (v) => (v != null && v.contains('@'))
                    ? null
                    : 'Enter a valid email',
              ),
              _buildInput(
                "Password",
                Icons.lock,
                _passController,
                isPassword: true,
                obscureText: _obscurePassword,
                toggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                validator: (v) =>
                (v != null && v.length >= 8) ? null : 'Password too short',
              ),
              _buildInput(
                "Confirm Password",
                Icons.lock_outline,
                _confirmPassController,
                isPassword: true,
                obscureText: _confirmObscurePassword,
                toggleObscure: () => setState(
                        () => _confirmObscurePassword = !_confirmObscurePassword),
                validator: (v) => v == _passController.text
                    ? null
                    : 'Passwords do not match',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text(
                    "Register",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account?",
                      style: TextStyle(color: Colors.white70),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Sign In"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
