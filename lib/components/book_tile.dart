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
          print('bạn vừa nhân getsture');
          Navigator.of(context).pushNamed('/infopage', arguments: linkImage);
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
