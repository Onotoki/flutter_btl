import 'package:flutter/material.dart';

class BookTile extends StatelessWidget {
  const BookTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: 150,
        margin: EdgeInsets.only(left: 20, bottom: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          child: Image.asset("lib/images/book.jpg", fit: BoxFit.cover),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
