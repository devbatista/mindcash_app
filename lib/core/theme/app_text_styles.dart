import 'package:flutter/material.dart';
import 'package:mindcash_app/core/theme/app_colors.dart';

final class AppTextStyles {
  const AppTextStyles._();

  static const headline = TextStyle(
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
  );

  static const sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
  );
}
