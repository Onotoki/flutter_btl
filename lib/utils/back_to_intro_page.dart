import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pages/Intropage/intro_page.dart';

class BackToIntroPage extends StatelessWidget {
  const BackToIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Kiểm tra trạng thái đăng nhập
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;

    // Nếu đã đăng nhập, không hiển thị gì (PhanDuoiBackToIntroPage sẽ lo)
    if (isLoggedIn) {
      return const SizedBox.shrink(); // Widget rỗng
    }

    // Nếu chưa đăng nhập, hiển thị nút "Create an account"
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) {
              return IntroPage(); // Navigates to IntroPage
            },
          ),
          (route) => false, // Removes all previous routes from the stack
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.green[900],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: Text(
              "Create an account",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
