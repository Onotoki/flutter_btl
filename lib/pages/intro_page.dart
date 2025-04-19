import 'package:btl/pages/home_page.dart';
import 'package:flutter/material.dart';



class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  void handleGoogleLogin(BuildContext context) {
    print("Đăng nhập với Google");
    // TODO: Thêm chức năng thật ở đây (Firebase, GoogleSignIn, v.v.)
  }

  void handleFacebookLogin(BuildContext context) {
    print("Đăng nhập với Facebook");
    // TODO: Thêm chức năng thật ở đây (Facebook SDK hoặc Firebase auth Facebook)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003E32),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, size: 30, color: Colors.white,),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomePage())); // quay lại hoặc thoát
            },
          )
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
              onTap: () => handleGoogleLogin(context),
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
                    Icon(Icons.g_mobiledata, size: 30),
                    SizedBox(width: 10),
                    Text(
                      "Continue with Google",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            // Facebook button
            GestureDetector(
              onTap: () => handleFacebookLogin(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF1877F2), // màu Facebook
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.facebook, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      "Continue with Facebook",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
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
                      style: const TextStyle(
                          color: Colors.blue, decoration: TextDecoration.underline),
                    ),
                    const TextSpan(text: " / "),
                    TextSpan(
                      text: "Privacy Policy",
                      style: const TextStyle(
                          color: Colors.blue, decoration: TextDecoration.underline),
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
