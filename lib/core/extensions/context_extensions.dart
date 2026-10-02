import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  bool get isTablet => screenWidth > 600;
  bool get isMobile => screenWidth <= 600;

  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: AppColors.success);
  }

  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: AppColors.error);
  }
}
