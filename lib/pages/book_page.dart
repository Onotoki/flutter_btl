import 'package:btl/components/book_tile.dart';
import 'package:btl/models/book.dart';
import 'package:btl/utils/back_to_intro_page.dart';
import 'package:btl/utils/phan_duoi_back_to_intro_page.dart';
import 'package:flutter/material.dart';

class BookPage extends StatelessWidget {
  const BookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 50, right: 20, left: 20),
            child: BackToIntroPage(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15, bottom: 20),
            child: PhanDuoiBackToIntroPage(),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "Happy Endings >",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (context, index) {
                Book book = Book(imagePath: "lib/images/book.jpg");
                return BookTile();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20, left: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "Top in Contemporary > ",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (context, index) {
                Book book = Book(imagePath: "lib/images/book.jpg");
                return BookTile();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20, left: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "Enimies to Lovers >",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (context, index) {
                Book book = Book(imagePath: "lib/images/book.jpg");
                return BookTile();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20, left: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "Love Stories >",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (context, index) {
                Book book = Book(imagePath: "lib/images/book.jpg");
                return BookTile();
              },
            ),
          ),
        ],
      ),
    );
  }
}
