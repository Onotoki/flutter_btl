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
          content: Text('Mã OTP không đúng. Vui lòng thử lại.'),
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
            content: Text('Email đã được đăng ký. Vui lòng đăng nhập.'),
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
        content: Text('Đăng ký thành công!'),
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
          content: Text('Lỗi: ${e.toString()}'),
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
        title:
            const Text("Xác thực OTP", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, size: 30, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const IntroPage()),
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
            const Spacer(),
            const Icon(Icons.email_outlined,
                size: 60, color: Colors.greenAccent),
            const SizedBox(height: 20),
            const Text(
              "Xác thực email",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Chúng tôi đã gửi mã xác thực đến ${widget.email}",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),

            // OTP Input
            TextField(
              controller: otpController,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white10,
                labelText: "Nhập mã OTP",
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.greenAccent),
                ),
                counterText: '',
              ),
            ),
            const SizedBox(height: 30),

            // Verify Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtpAndRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        "Xác thực",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Gửi lại mã",
                  style: TextStyle(
                    color: Colors.white70,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
