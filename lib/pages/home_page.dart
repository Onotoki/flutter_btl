import 'package:flutter/material.dart';

import 'book_page.dart';
import 'library_page.dart';
import 'more_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  //Danh sách trang
  List<Widget> _pages = [
    //Home
    BookPage(),

    //Library
    LibraryPage(),

    //More
    MorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      backgroundColor: Colors.grey[900],
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
            label: "Home",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Library"),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: "More"),
        ],
      ),
    );
  }
}
