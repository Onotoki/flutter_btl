import 'package:flutter/material.dart';

class PhanDuoiBackToIntroPage extends StatelessWidget {
  const PhanDuoiBackToIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}
