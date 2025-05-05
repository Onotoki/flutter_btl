import 'package:btl/pages/Intropage/register_page.dart';
import 'package:btl/pages/home_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login_page.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      print("Đăng nhập Google thành công!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      print("Lỗi đăng nhập Google: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003E32),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, size: 30, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              ); // quay lại hoặc thoát
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            const Icon(Icons.grid_view, size: 60, color: Colors.greenAccent),
            const SizedBox(height: 20),
            const Text(
              "Sign in to Apptruyen",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Create an account or log in to save your reading progress.",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 30),
            // Google button
            GestureDetector(
              onTap: () => signInWithGoogle(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/image/Google__G__logo.png',height: 30,width: 30,),
                    SizedBox(width: 10),
                    Text(
                      "Continue with Google",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            //Email button
            const SizedBox(height: 30),
            GestureDetector(
              onTap:
                  () => (Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  )),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.email, size: 30),
                    SizedBox(width: 10),
                    Text("Continue with Email", style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),
            Center(
              child: Text.rich(
                TextSpan(
                  text: "Don't have an account?  ",
                  style: const TextStyle(color: Colors.white70, fontSize: 23),
                  children: [
                    TextSpan(
                      text: "Sign up",
                      style: const TextStyle(color: Colors.greenAccent),
                      recognizer:
                          TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegisterPage(),
                                ),
                              );
                            },
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const Spacer(),
            Center(
              child: Text.rich(
                TextSpan(
                  text: "By continuing, you agree to our ",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  children: [
                    TextSpan(
                      text: "Terms of Service",
                      style: const TextStyle(color: Colors.blue),
                    ),
                    const TextSpan(text: " / "),
                    TextSpan(
                      text: "Privacy Policy",
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}
