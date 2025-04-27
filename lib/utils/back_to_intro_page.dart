import 'package:flutter/material.dart';

import '../pages/Intropage/intro_page.dart';

class BackToIntroPage extends StatelessWidget {
  const BackToIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) {
              return IntroPage(); // Navigates to IntroPage
            },
          ),
          (route) => false, // Removes all previous routes from the stack
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.green[900],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: Text(
              "Create an account",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
