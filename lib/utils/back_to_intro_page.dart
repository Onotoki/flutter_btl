import 'package:flutter/material.dart';
import '../pages/Intropage/intro_page.dart';
import '../pages/search_page.dart';

class BackToIntroPage extends StatelessWidget {
  const BackToIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
          maxHeight: 105), // Giới hạn chiều cao để tránh dư phần màu đen
      color: Colors.grey[900],
      padding: const EdgeInsets.all(8), // Giảm padding tổng thể
      child: Column(
        children: [
          // Nút điều hướng về IntroPage
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => IntroPage()),
                (route) => false,
              );
            },
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 24, 136, 69),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(6), // Giảm padding ở nút
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

          // Phần logo, tiêu đề và nút search
          Padding(
            padding: const EdgeInsets.only(
                top: 15), // Giảm khoảng cách thừa ở trên/dưới
            child: Row(
              children: [
                const Icon(Icons.grid_view,
                    size: 40, color: Colors.greenAccent),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    "Books",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 23,
                    ),
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SearchPage()),
                    );
                  },
                  child: Icon(Icons.search, color: Colors.white, size: 35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
