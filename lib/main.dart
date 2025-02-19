import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xalgo/ExecutedTrade.dart';
import 'package:xalgo/SignUpPage.dart';
import 'package:xalgo/HomePage.dart';
import 'package:xalgo/SplashScreen.dart';
import 'package:xalgo/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xalgo/theme/theme_manage.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xalgo/SignUpPage.dart';
import 'package:xalgo/HomePage.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          theme: ThemeData.light(), // Light mode theme
          darkTheme: ThemeData.dark(), // Dark mode theme
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: SplashScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
