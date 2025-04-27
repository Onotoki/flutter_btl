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
          child: const Icon(
            Icons.grid_view,
            size: 40,
            color: Colors.green,
          ),
        ),

        //Books
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            "Books",
            style: TextStyle(
              // color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 23,
            ),
          ),
        ),
        Spacer(),
        //Search Icon
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: Icon(Icons.search, size: 35),
        ),
      ],
    );
  }
}
