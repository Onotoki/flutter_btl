import 'package:flutter/material.dart';
import '../pages/search_page.dart';

class PhanDuoiBackToIntroPage extends StatelessWidget {
  const PhanDuoiBackToIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Logo
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child:
              const Icon(Icons.grid_view, size: 40, color: Colors.greenAccent),
        ),

        // Books
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            "Books",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 23,
            ),
          ),
        ),
        Spacer(),

        // Search Icon with GestureDetector
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchPage(),
                ),
              );
            },
            child: Icon(Icons.search, size: 35),
          ),
        ),
      ],
    );
  }
}
