import 'dart:convert';
import 'dart:math';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:xalgo/secret/secret.dart';
import 'package:xalgo/widgets/drawer_widget.dart';
import 'package:provider/provider.dart';
import 'package:xalgo/theme/theme_manage.dart';
import 'package:xalgo/theme/app_colors.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class Subcribed extends StatefulWidget {
  const Subcribed({super.key});
  @override
  State<Subcribed> createState() => _SubcribedState();
}

class _SubcribedState extends State<Subcribed> {
  bool? isLoading = false;
  List<String> deployedBrokerIds = [];
  List<String> brokerId = [];
  List<String> subscribedStrategies = [];
  List<String> strategyData = [];
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  //fetch gmail from stoargeee
  Future<String?> getEmail() async {
    try {
      String? userEmail = await secureStorage.read(key: 'Email');
      print('Email>>>>>>>>>>:$userEmail');
      return userEmail;
    } catch (e) {
      print('Error retrieving email: $e');
    }
    return null;
  }

  //fetch data from app data
  Future<void> fetchData() async {
    print("user is in Subcribed page and fetch data from app");

    String? userSchemaJson = await secureStorage.read(key: "backendData");

    if (userSchemaJson != null) {
      String? email = await getEmail();
      Map<String, dynamic> userData = jsonDecode(userSchemaJson);

      deployedBrokerIds =
          (userData['DeployedStrategiesBrokerIds'] as List?)?.cast<String>() ??
              [];

      //update user data
      final response = await http.post(
        Uri.parse('${Secret.backendUrl}/getMarketPlaceData'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        String newUserSchemaJson = response.body;
        await secureStorage.write(key: 'backendData', value: newUserSchemaJson);
        print(newUserSchemaJson);
      } else {
        print(
            'Failed to update user data. Status code: ${response.statusCode}');
      }
    } else {
      print('No backendData found in storage.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeProvider>(context);
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {},
        child: Scaffold(
            key: _scaffoldKey, // Assign the key to Scaffold
            endDrawer: Drawer(),
            backgroundColor: themeManager.isDarkMode == ThemeMode.dark
                ? AppColors.darkPrimary
                : AppColors.lightPrimary,
            body: PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {},
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: themeManager.isDarkMode == ThemeMode.dark
                        ? AppColors.darkPrimary
                        : AppColors.lightPrimary,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    centerTitle: true,
                    title: Text(
                      'Subcribed',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: themeManager.isDarkMode == ThemeMode.dark
                              ? AppColors.lightPrimary
                              : AppColors.darkPrimary),
                    ),
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: themeManager.isDarkMode == ThemeMode.dark
                            ? Image.asset(
                                'assets/images/darklogo.png',
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                'assets/images/lightlogo.png',
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    actions: [
                      Builder(
                        // Ensure correct context
                        builder: (context) => IconButton(
                          icon: Icon(Icons.menu,
                              color: themeManager.isDarkMode == ThemeMode.dark
                                  ? AppColors.lightPrimary
                                  : AppColors.darkPrimary),
                          onPressed: () {
                            Scaffold.of(context).openEndDrawer();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                body: const SubcribedPage(),
              ),
            )));
  }
}

class SubcribedPage extends StatelessWidget {
  const SubcribedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center();
  }
}
