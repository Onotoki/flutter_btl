import 'package:btl/pages/Intropage/intro_page.dart';
import 'package:btl/pages/Intropage/otp_reiceiver_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  //
  void handleRegister() {
    if (_formKey.currentState!.validate()) {
      final email = emailController.text.trim();

      // TODO: Gửi OTP tới backend nếu có

      // ✅ Điều hướng sang trang nhập OTP
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OtpReceiverPage(email: email)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003E32),
      appBar: AppBar(
        title: const Text("Register", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, size: 30, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IntroPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.grid_view, size: 60, color: Colors.greenAccent),
              const SizedBox(height: 10),
              const Text(
                "Sign Up For Free",
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),

              // Email
              buildInputField(
                label: "Email",
                controller: emailController,
                obscureText: false,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Please enter email";
                  if (!isValidEmail(value)) return "Invalid email";
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Password
              buildInputField(
                label: "Password",
                controller: passwordController,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Please enter password";
                  if (value.length < 6) return "Password minimum 6 characters";
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Confirm password
              buildInputField(
                label: "Password Confirmation",
                controller: confirmPasswordController,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Please confirm password";
                  if (value != passwordController.text)
                    return "Confirm password does not match";
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Nút đăng ký
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInputField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.greenAccent),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}
