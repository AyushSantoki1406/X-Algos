import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xalgo/SignUpPage.dart';
import 'package:xalgo/HomePage.dart'; // Assuming you have a HomePage widget.
import 'package:xalgo/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'X Algos',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Function to check if the user is logged in
  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? loggedIn = prefs.getBool('isLoggedIn');

    setState(() {
      // If isLoggedIn is not set, default it to false
      isLoggedIn = loggedIn ?? false;
    });

    Timer(
      Duration(seconds: 3),
      () {
        // Navigate based on the value of isLoggedIn
        if (isLoggedIn) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Home()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SignUpPage()),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: AppColors.bd_black,
        child: FlutterLogo(size: MediaQuery.of(context).size.height));
  }
}
