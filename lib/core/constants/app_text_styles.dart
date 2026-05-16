import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    fontFamily: 'Phetsarath',
    color: AppColors.textMain,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: 'Phetsarath',
    color: AppColors.textSecondary,
  );
  
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    fontFamily: 'Phetsarath',
    color: AppColors.textSecondary,
  );
}