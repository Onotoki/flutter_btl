import 'package:btl/utils/back_to_intro_page.dart';
import 'package:flutter/material.dart';

class BookPage extends StatelessWidget {
  const BookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 50, right: 20, left: 20),
            child: BackToIntroPage(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Row(
              children: [
                //Logo
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Image.asset("lib/images/logo.webp", width: 40),
                ),

                //Books
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
                //Search Icon
                Padding(
                  padding: const EdgeInsets.only(right: 15),
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
