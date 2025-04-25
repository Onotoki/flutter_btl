import 'package:flutter/material.dart';

class Button_Info extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color foregroundColor;
  final int flex;
  final VoidCallback ontap;

  const Button_Info({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.flex,
    required this.ontap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: ElevatedButton(
        onPressed: ontap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            text,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
