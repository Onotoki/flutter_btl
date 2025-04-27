import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    surface: Colors.white,
    onSurface: Colors.grey.shade700,
    primary: Colors.grey.shade300,
    secondary: Colors.grey.shade100,
  ),
);
