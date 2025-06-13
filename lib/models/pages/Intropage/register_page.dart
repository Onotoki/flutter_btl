import 'dart:convert';

import 'package:btl/models/pages/Intropage/intro_page.dart';
import 'package:btl/models/pages/Intropage/otp_reiceiver_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emailjs/emailjs.dart';
import 'package:http/http.dart' as http;

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
  final TextEditingController nicknameController = TextEditingController();

  String? generatedOtp;

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> sendOtpEmail(String email, String otp) async {
    const url = 'https://api.emailjs.com/api/v1.0/email/send';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': 'service_m6uo75i',
          'template_id': 'template_jpqztvs',
          'user_id': '7lv6xkhogmqvmFhEK',
          'template_params': {
            'email': email,
            'passcode': otp,
          },
        }),
      );

      if (response.statusCode == 200) {
        print('OTP đã gửi thành công!');
      } else {
        print('Gửi OTP thất bại: ${response.body}');
      }
    } catch (e) {
      print('Lỗi gửi OTP: $e');
    }
  }

  Future<void> handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final email = emailController.text.trim();
      final nickname = nicknameController.text.trim();

      // Kiểm tra nickname có sẵn
      final isAvailable = await FirebaseFirestore.instance
          .collection('users')
          .where('nickname', isEqualTo: nickname)
          .get()
          .then((snapshot) => snapshot.docs.isEmpty);

      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nickname đã được sử dụng. Vui lòng chọn tên khác.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final methods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email đã được đăng ký. Vui lòng đăng nhập.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      generatedOtp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000))
          .toString();
      await sendOtpEmail(email, generatedOtp!);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpReceiverPage(
            email: email,
            generatedOtp: generatedOtp!,
            password: passwordController.text.trim(),
            nickname: nickname,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003E32),
      appBar: AppBar(
        title: const Text("Đăng ký", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, size: 30, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const IntroPage()));
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
                "Đăng ký miễn phí",
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              // Nickname
              buildInputField(
                label: "Nickname",
                controller: nicknameController,
                obscureText: false,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Vui lòng nhập nickname";
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Email
              buildInputField(
                label: "Email",
                controller: emailController,
                obscureText: false,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Vui lòng nhập email";
                  if (!isValidEmail(value)) return "Email không hợp lệ";
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Password
              buildInputField(
                label: "Mật khẩu",
                controller: passwordController,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Vui lòng nhập mật khẩu";
                  if (value.length < 6) return "Mật khẩu tối thiểu 6 ký tự";
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Confirm password
              buildInputField(
                label: "Xác nhận mật khẩu",
                controller: confirmPasswordController,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Vui lòng xác nhận mật khẩu";
                  if (value != passwordController.text)
                    return "Mật khẩu xác nhận không khớp";
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
                    "Đăng ký",
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
