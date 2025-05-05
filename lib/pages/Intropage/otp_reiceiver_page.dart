import 'package:btl/pages/Intropage/intro_page.dart';
import 'package:btl/pages/Intropage/register_page.dart'; // Thêm HomePage vào
import 'package:btl/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

int attempts = 0;

class OtpReceiverPage extends StatefulWidget {
  final String email;
  final String generatedOtp;
  final String password; // Nhận OTP được tạo từ RegisterPage

  const OtpReceiverPage({
    super.key,
    required this.email,
    required this.generatedOtp,
    required this.password,
  });

  @override
  State<OtpReceiverPage> createState() => _OtpReceiverPageState();
}

class _OtpReceiverPageState extends State<OtpReceiverPage> {
  final TextEditingController otpController = TextEditingController();

  void verifyOtp() async {
  if (attempts >= 5) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Too many incorrect attempts. Please try again later.'),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }

  if (otpController.text.trim() == widget.generatedOtp) {
    try {
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(widget.email);

      if (methods.isEmpty) {
        // Tài khoản chưa tồn tại => tạo mới
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: widget.email,
          password: widget.password,
        );

        await FirebaseFirestore.instance.collection('users').doc(widget.email).set({
          'email': widget.email,
          'created_at': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account already exists. Logging in...'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Dù là tạo mới hay đã tồn tại -> điều hướng về Intro hoặc Home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const IntroPage()), // hoặc HomePage
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  } else {
    attempts++;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invalid OTP. Attempts left: ${5 - attempts}'),
        backgroundColor: Colors.redAccent,
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
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const IntroPage()));
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
            Text("Enter the verification code sent to:",
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
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
                onPressed: verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
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
