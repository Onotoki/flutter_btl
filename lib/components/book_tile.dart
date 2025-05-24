import 'package:btl/pages/info_book.dart';
import 'package:flutter/material.dart';

class BookTile extends StatelessWidget {
  String linkImage;
  BookTile({super.key, required this.linkImage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 15),
      child: GestureDetector(
        onTap: () {
          try {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Info(),
                    settings: RouteSettings(arguments: linkImage)));
          } catch (e) {
            debugPrint('Navigation error: $e');
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cannot open book: ${e.toString()}')));
          }
        },
        child: Container(
          width: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            child: Image.asset(linkImage, fit: BoxFit.cover),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
