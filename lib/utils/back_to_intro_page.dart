import 'package:btl/cubit/theme_cubit.dart';
import 'package:btl/cubit/theme_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../pages/Intropage/intro_page.dart';
import '../pages/search_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BackToIntroPage extends StatelessWidget {
  const BackToIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final isDarkTheme = context.watch<ThemeCubit>().state is DarkTheme;

    // Màu sắc động theo theme
    final backgroundColor = isDarkTheme ? Colors.grey[900]! : Colors.white;
    final iconColor = isDarkTheme ? Colors.greenAccent : Colors.green[800];
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    return Container(
      
      constraints: BoxConstraints(
        minHeight: isLoggedIn ? 70 : 110, // Thay maxHeight bằng minHeight
        maxHeight: 110, // Giới hạn tối đa
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDarkTheme ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(bottom: 8), // Giảm margin
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const IntroPage()),
                    (route) => false,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12), // Điều chỉnh padding
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 24, 136, 69),
                    borderRadius: BorderRadius.circular(10),
                  ),
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
            ),

          // Phần header
          SizedBox(
            // Bọc trong SizedBox để kiểm soát kích thước
            height: 60, // Chiều cao cố định
            child: Row(
              children: [
                const Icon(
                  Icons.grid_view,
                  size: 40,
                  color: Colors.greenAccent,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    "Books",
                    style: TextStyle(
                      color: textColor, // Bật lại màu trắng
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.search,
                    color: iconColor,
                    size: 35,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SearchPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
