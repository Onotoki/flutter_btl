import 'package:btl/pages/info_book.dart';
import 'package:flutter/material.dart';

class BookTile extends StatelessWidget {
  final String linkImage;

  const BookTile({super.key, required this.linkImage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 15),
      child: GestureDetector(
        onTap: () {
          print('Bạn vừa nhấn Gesture');
          // Navigator.of(context).pushNamed('/infopage',
          //     arguments: linkImage); // Only passing the image
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => Info()));
        },
        child: Container(
          width: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(linkImage, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}
