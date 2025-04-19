import 'package:btl/pages/canhan_page.dart';
import 'package:btl/pages/congdong_page.dart';
import 'package:btl/pages/kesach_page.dart';
import 'package:btl/pages/khampha_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  //Danh sách trang
  List<Widget> _pages = [
    //Kệ sách
    KeSachPage(),

    //Khám phá
    KhamPhaPage(),

    //Cộng đồng
    CongDongPage(),

    //Cá nhân
    CaNhanPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(
          "App Đọc Truyện Số Một Việt Nam",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          setState(() {
            _index = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Kệ Sách",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Khám phá"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Cộng đồng"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Cá nhân"),
        ],
      ),
    );
  }
}
