import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.carrot,
          primary: AppColors.carrot,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.black,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.carrot,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 17),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.gray50,
          selectedColor: AppColors.carrotLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.carrot,
          linearMinHeight: 3,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.black,
          elevation: 4,
        ),
      );
}
