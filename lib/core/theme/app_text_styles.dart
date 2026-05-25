import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const String fontName = 'Tajawal'; // Beautiful Arabic/English typeface

  static const TextStyle display = TextStyle(
    fontFamily: fontName,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
    height: 1.3,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: fontName,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
    height: 1.3,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontName,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontName,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    height: 1.4,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontName,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textMedium,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontName,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
    height: 1.4,
  );

  static const TextStyle price = TextStyle(
    fontFamily: fontName,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryDark,
    height: 1.2,
  );

  static const TextStyle priceOld = TextStyle(
    fontFamily: fontName,
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
    decoration: TextDecoration.lineThrough,
    height: 1.2,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontName,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    letterSpacing: 0.5,
    height: 1.2,
  );
}
