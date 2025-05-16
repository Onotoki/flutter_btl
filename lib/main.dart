import 'package:btl/pages/Intropage/intro_page.dart';
import 'package:btl/pages/Intropage/login_page.dart';
import 'package:btl/pages/Intropage/register_page.dart';
import 'package:btl/pages/home_page.dart';
import 'package:btl/pages/info_book.dart';
import 'package:flutter/material.dart';
import 'package:btl/pages/Intropage/intro_page.dart'; // Màn hình mở đầu
import 'package:btl/pages/book_page.dart'; // Màn hình danh sách sách

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Đảm bảo Flutter được khởi tạo

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: IntroPage(),
      routes: {
        '/infopage': (context) => Info(),
      },
    );
  }
}
