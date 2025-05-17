import 'package:btl/pages/categories_page.dart';
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

    //Categories
    CategoriesPage(),

    //Library
    LibraryPage(),

    //More
    Person(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(top: 3),
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
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
                icon: Icon(Icons.search_sharp), label: "Categories"),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: "Library"),
            BottomNavigationBarItem(icon: Icon(Icons.menu), label: "Person"),
          ],
        ),
      ),
    );
  }
}
