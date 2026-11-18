import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CategoryUtils {
  CategoryUtils._();

  static IconData icon(String category) {
    switch (category.toLowerCase()) {
      case 'necessity':    return Icons.home_outlined;
      case 'convenience':  return Icons.local_dining_outlined;
      case 'social':       return Icons.people_outline_rounded;
      case 'aspirational': return Icons.auto_awesome_outlined;
      case 'invisible':    return Icons.receipt_long_outlined;
      default:             return Icons.help_outline_rounded;
    }
  }

  static Color color(String category) {
    switch (category.toLowerCase()) {
      case 'necessity':    return AppColors.primary;
      case 'convenience':  return const Color(0xFF64B5F6);
      case 'social':       return const Color(0xFFFFB74D);
      case 'aspirational': return const Color(0xFFBA68C8);
      case 'invisible':    return AppColors.textHint;
      default:             return AppColors.textSecondary;
    }
  }

  static String label(String category) {
    switch (category.toLowerCase()) {
      case 'necessity':    return 'Necessity';
      case 'convenience':  return 'Convenience';
      case 'social':       return 'Social';
      case 'aspirational': return 'Aspirational';
      case 'invisible':    return 'Invisible';
      case 'review':       return 'Unlabeled';
      default:             return category;
    }
  }

  static String formatAmount(double amount) {
    final formatted = amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'Ksh $formatted';
  }
}
