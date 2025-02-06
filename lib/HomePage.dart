import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shimmer/main.dart';
import 'package:xalgo/main.dart';
import 'package:xalgo/widgets/drawer_widget.dart';
import 'package:provider/provider.dart';
import 'package:xalgo/theme/theme_manage.dart';
import 'package:xalgo/theme/app_colors.dart';
import 'package:xalgo/secret/secret.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  //function for gmai
  Future<String?> getEmail() async {
    try {
      String? email = await secureStorage.read(key: 'Email');
      String? userSchemaJson = await secureStorage.read(key: "backendData");

      if (userSchemaJson != null) {
        Map<String, dynamic> userData = jsonDecode(userSchemaJson);
      } else {
        print('No backendData found in storage.');
      }

      return email;
    } catch (e) {
      print('Error fetching email: $e');
      return null;
    }
  }

  //fetch userdata from backend and store to shared prefences
  Future<Map<String, dynamic>> fetchProfile() async {
    String? email = await getEmail();
    final url = Uri.parse('${Secret.backendUrl}/dbschema');

    final Map<String, String> body = {'Email': email.toString()};
    final response = await http.post(url, body: body);

    Future<void> loadUserSchema() async {
      try {
        if (response != null) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          Map<String, dynamic> userSchema = jsonDecode(response.body);
          await secureStorage.write(
              key: 'backendData', value: jsonEncode(userSchema));

          // Also store in SharedPreferences for fast access
          await prefs.setString('userSchema', jsonEncode(userSchema));
        } else {
          log('No user schema found in storage.');
        }
      } catch (e) {
        log('Error loading user schema: $e');
      }
    }

    loadUserSchema();

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load profile: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    return Scaffold(
        key: _scaffoldKey, // Assign the key to Scaffold
        endDrawer: AppDrawer(),
        backgroundColor: themeManager.themeMode == ThemeMode.dark
            ? AppColors.darkPrimary
            : AppColors.lightPrimary,
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {},
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                pinned: true,
                backgroundColor: themeManager.themeMode == ThemeMode.dark
                    ? AppColors.darkPrimary
                    : AppColors.lightPrimary,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: true,
                title: Text(
                  'Dashboard',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: themeManager.themeMode == ThemeMode.dark
                          ? AppColors.lightPrimary
                          : AppColors.darkPrimary),
                ),
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: themeManager.themeMode == ThemeMode.dark
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
                          color: themeManager.themeMode == ThemeMode.dark
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
            body: FutureBuilder<Map<String, dynamic>>(
              future: fetchProfile(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    color: themeManager.themeMode == ThemeMode.dark
                        ? AppColors.darkPrimary
                        : AppColors.lightPrimary,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData) {
                  SharedPreferences.getInstance().then((prefs) {
                    prefs.setBool('isLoggedIn', false);

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SplashScreen(),
                        ),
                      );
                    });
                  });

                  return Container(); // Ensure a Widget is always returned
                } else if (snapshot.hasData) {
                  final data = snapshot.data!;
                  return Container(
                    width: double.infinity,
                    color: themeManager.themeMode == ThemeMode.dark
                        ? AppColors.darkPrimary
                        : AppColors.lightPrimary,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            color: themeManager.themeMode == ThemeMode.dark
                                ? AppColors.bd_black
                                : AppColors.bd_white,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              width: double.infinity,
                              padding: EdgeInsets.all(16),
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 8.0, right: 8),
                                    child: Column(
                                      children: [
                                        Text(
                                          "P&L",
                                          style: TextStyle(
                                              color: themeManager.themeMode ==
                                                      ThemeMode.dark
                                                  ? AppColors.lightPrimary
                                                  : AppColors.darkPrimary),
                                        ),
                                        Text("₹",
                                            style: TextStyle(
                                                color: themeManager.themeMode ==
                                                        ThemeMode.dark
                                                    ? AppColors.lightPrimary
                                                    : AppColors.darkPrimary))
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 8.0, right: 8),
                                    child: Column(
                                      children: [
                                        Text("Capital",
                                            style: TextStyle(
                                                color: themeManager.themeMode ==
                                                        ThemeMode.dark
                                                    ? AppColors.lightPrimary
                                                    : AppColors.darkPrimary)),
                                        Text(
                                          data['capital'] ?? '₹0.0',
                                          style: TextStyle(
                                              color: Color(0xFF4CAF50)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SplashScreen(),
                      ),
                    );
                  });
                  return Container(); // This ensures a Widget is always returned
                }
              },
            ),
          ),
        ));
  }
}
