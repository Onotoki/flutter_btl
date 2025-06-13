import 'package:btl/models/pages/categories_page.dart';
import 'package:btl/models/pages/library_page.dart';
import 'package:flutter/material.dart';

import 'book_page.dart';
import 'more_page.dart';
// import 'categories_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  //Danh sách trang
  final List<Widget> _pages = [
    //Home
    const BookPage(),

    //Categories
    const CategoriesPage(),

    //Categories
    // CategoriesPage(),

    //Library
    const LibraryPage(),

    //More
    Person(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body: _pages[_index],

      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 3),
        decoration: BoxDecoration(
            border: Border(
                top: BorderSide(color: Theme.of(context).colorScheme.primary))),
        child: BottomNavigationBar(
          enableFeedback: false,
          selectedItemColor: Colors.green,
          onTap: (index) {
            setState(() {
              _index = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          currentIndex: _index,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Trang chủ"),
            BottomNavigationBarItem(
                icon: Icon(Icons.category), label: "Thể loại"),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: "Thư viện"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Cá nhân"),
          ],
        ),
      ),
    );
  }
}
