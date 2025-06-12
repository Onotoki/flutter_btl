import 'package:btl/pages/Intropage/intro_page.dart';
import 'package:btl/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtpReceiverPage extends StatefulWidget {
  final String email;
  final String generatedOtp;
  final String password;
  final String nickname;

  const OtpReceiverPage({
    super.key,
    required this.email,
    required this.generatedOtp,
    required this.password,
    required this.nickname,
  });

  @override
  State<OtpReceiverPage> createState() => _OtpReceiverPageState();
}

class _OtpReceiverPageState extends State<OtpReceiverPage> {
  final TextEditingController otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyOtpAndRegister() async {
    setState(() => _isLoading = true);

    final enteredOtp = otpController.text.trim();

    if (enteredOtp != widget.generatedOtp) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect OTP. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      // Kiểm tra email đã tồn tại chưa
      final methods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(widget.email);

      if (methods.isNotEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email already registered. Please log in.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Tạo tài khoản mới
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      // Lưu thông tin user vào Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.email)
          .set({
        'uid': userCredential.user?.uid,
        'email': widget.email,
        'nickname': widget.nickname,
        'createdAt': FieldValue.serverTimestamp(),
        'authProvider': 'email',
      });

      // Đăng nhập thành công
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Registration successful!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ));

      // Điều hướng về trang chính
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003E32),
      appBar: AppBar(
        title: const Text("Verify OTP", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, size: 30, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            const Icon(Icons.email_outlined,
                size: 60, color: Colors.greenAccent),
            const SizedBox(height: 10),
            const Text("Enter the verification code sent to:",
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 6),
            Text(widget.email,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 30),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "OTP code",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white10,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.greenAccent),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtpAndRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        "Verify",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
