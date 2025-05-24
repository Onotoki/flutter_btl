import 'package:flutter/material.dart';
import '../pages/Intropage/intro_page.dart';
import '../pages/search_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BackToIntroPage extends StatelessWidget {
  const BackToIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: isLoggedIn ? 80 : 120,
      ),
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Điều chỉnh padding tổng
      child: Column(
        mainAxisSize: MainAxisSize.min, // Thêm dòng này để column co lại vừa đủ content
        children: [
          if (!isLoggedIn) ...[
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const IntroPage()),
                  (route) => false,
                );
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12), // Thêm margin dưới
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 24, 136, 69),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(12), // Tăng padding bên trong nút
                child: const Center(
                  child: Text(
                    "Create an account",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
          
          // Phần logo và tiêu đề
          Container(
            padding: const EdgeInsets.only(bottom: 8), // Padding dưới bằng với trên
            child: Row(
              children: [
                const Icon(Icons.grid_view, size: 40, color: Colors.greenAccent),
                const Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Text(
                    "Books",
                    style: TextStyle(
                      // color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SearchPage()),
                    );
                  },
                  child: const Icon(Icons.search, color: Colors.white, size: 35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}