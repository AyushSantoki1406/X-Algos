import 'package:flutter/material.dart';
import 'package:xalgo/theme/app_colors.dart';
import 'package:xalgo/theme/theme_manage.dart';
import 'package:provider/provider.dart';

class Errorpage extends StatelessWidget {
  const Errorpage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return Scaffold(
      body: Container(
        color: themeManager.themeMode == ThemeMode.dark
            ? AppColors.darkPrimary
            : AppColors.lightPrimary,
        child: Center(
          child: Text(
            'An error occurred, please try again.',
            style: TextStyle(
              color: themeManager.themeMode == ThemeMode.dark
                  ? AppColors.bd_black
                  : AppColors.lightBackground,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}
