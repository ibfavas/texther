import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuthException
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final email = _emailController.text.trim();

    try {
      await _authService.sendPasswordResetEmail(email);
      setState(() {
        _message = "A password reset link has been sent to the registered email. Please check your inbox and spam folder.";
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'generic-password-reset-message') {
        setState(() {
          _message = "${e.message} Please check your inbox and spam folder.";
        });
      } else {
        print("Forgot Password Error: ${e.code} - ${e.message}");
        setState(() {
          _message = "Error sending reset link: Please try again later.";
        });
      }
    } catch (e) {
      print("Unexpected error in ForgotPasswordScreen: $e");
      setState(() {
        _message = "An unexpected error occurred. Please try again.";
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildInput({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.white70),
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: viewInsets > 0 ? viewInsets + 16 : 32,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BackButton(color: Colors.white),
                const SizedBox(height: 30),
                const Text(
                  "Forgot\nPassword?",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  "Enter your registered email to receive a password reset link.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 20),
                _buildInput(
                  hint: "Email",
                  icon: Icons.email,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                  value == null || !value.contains("@") ? "Enter a valid email" : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Send Reset Link", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: _message!.startsWith("A password reset link has been sent") || _message!.startsWith("If an account exists") ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}