import 'package:flutter/material.dart';

class AppColors {
  // Private constructor — prevents instantiation
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF1DB954);      // Tajirika green
  static const Color primaryDark = Color(0xFF158A3C);
  static const Color accent = Color(0xFF00C9A7);

  // Backgrounds
  static const Color background = Color(0xFF0D0D0D);   // Near black
  static const Color surface = Color(0xFF1A1A1A);      // Card background
  static const Color surfaceLight = Color(0xFF2A2A2A); // Elevated card

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textHint = Color(0xFF616161);

  // Semantic
  static const Color success = Color(0xFF1DB954);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFEF5350);

  // PIN Pad
  static const Color pinFilled = Color(0xFF1DB954);
  static const Color pinEmpty = Color(0xFF2A2A2A);
}