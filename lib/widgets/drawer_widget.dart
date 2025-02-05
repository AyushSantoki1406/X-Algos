import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:xalgo/Deployed.dart';
import 'package:xalgo/ExecutedTrade.dart';
import 'package:xalgo/HomePage.dart';
import 'package:xalgo/LiveTrade.dart';
import 'package:xalgo/ManageBroker.dart';
import 'package:xalgo/Marketplace.dart';
import 'package:xalgo/PaperTrade.dart';
import 'package:xalgo/Subcribed.dart';
import 'package:xalgo/theme/app_colors.dart';
import 'package:xalgo/main.dart';
import 'package:provider/provider.dart';
import 'package:xalgo/theme/theme_manage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeManager()),
      ],
      child: AppDrawer(),
    ),
  );
}

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: MyAccountPage(),
    );
  }
}

class MyAccountPage extends StatefulWidget {
  @override
  _MyAccountPageState createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  //function to get gmail

  Future<String?> getEmail() async {
    try {
      String? email = await secureStorage.read(key: 'Email');
      if (email == null) {
        print('No email found in secure storage.');
      } else {
        print('Email retrieved: $email');
      }
      return email;
    } catch (e) {
      print('Error reading email from secure storage: $e');
      return null;
    }
  }

  Future<String?> callBackendRoute() async {
    try {
      final SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      String? userSchemaJson = await secureStorage.read(key: "backendData");

      if (userSchemaJson == null) {
        return null;
      }

      Map<String, dynamic> userData = jsonDecode(userSchemaJson);
      print(userData['']);

      return userData['XalgoID'];
    } catch (e) {
      return null;
    }
  }

  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Deleting all secure storage data, including email and backend data
    await secureStorage.deleteAll();

    // Optionally, you can also delete specific keys if needed:
    await secureStorage.delete(key: 'Email');
    await secureStorage.delete(key: 'backendData'); // Adjust key name if needed

    // Set the login status to false in SharedPreferences
    await prefs.setBool('isLoggedIn', false);

    // Navigate to the SplashScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SplashScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) {
            return;
          }
        },
        child: Scaffold(
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
                      'My Account',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: themeManager.themeMode == ThemeMode.dark
                              ? AppColors.lightPrimary
                              : AppColors.darkPrimary),
                    ),
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8),
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
                body: FutureBuilder<String?>(
                  future: getEmail(),
                  builder: (context, snapshot) {
                    print(snapshot);
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    } else if (snapshot.hasData) {
                      String email = snapshot.data!;
                      return FutureBuilder<String?>(
                        future: callBackendRoute(),
                        builder: (context, backendSnapshot) {
                          if (backendSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (backendSnapshot.hasError) {
                            return Center(
                                child: Text("Error: ${backendSnapshot.error}"));
                          } else if (backendSnapshot.connectionState ==
                              ConnectionState.done) {
                            String? algoID = backendSnapshot.data;
                            return ListView(
                              children: [
                                ListTile(
                                  title: Text(
                                    "$email",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: themeManager.themeMode ==
                                                ThemeMode.dark
                                            ? AppColors.lightPrimary
                                            : AppColors.darkPrimary),
                                  ),
                                  subtitle: Text(
                                    "UserID: $algoID",
                                    style: TextStyle(
                                        color: themeManager.themeMode ==
                                                ThemeMode.dark
                                            ? AppColors.lightPrimary
                                            : AppColors.darkPrimary),
                                  ),
                                ),
                                Divider(),
                                _buildListTile(Icons.settings, "Dashboard",
                                    onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Home(),
                                      settings: RouteSettings(),
                                      fullscreenDialog: false,
                                    ),
                                  );
                                }),
                                ExpansionTile(
                                  leading: Icon(Icons.analytics,
                                      color: themeManager.themeMode ==
                                              ThemeMode.dark
                                          ? AppColors.lightPrimary
                                          : AppColors.darkPrimary),
                                  title: Text(
                                    "Orders",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: themeManager.themeMode ==
                                              ThemeMode.dark
                                          ? AppColors
                                              .lightPrimary // Text color for dark mode
                                          : AppColors
                                              .darkPrimary, // Text color for light mode
                                    ),
                                  ),
                                  children: [
                                    _buildSubListTile("LiveTrade", onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => LiveTradePage(),
                                          settings: RouteSettings(),
                                          fullscreenDialog: false,
                                        ),
                                      );
                                    }),
                                    _buildSubListTile("ExecutedTrade",
                                        onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ExecutedTrade(),
                                          settings: RouteSettings(),
                                          fullscreenDialog: false,
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                                ExpansionTile(
                                  leading: Icon(Icons.analytics,
                                      color: themeManager.themeMode ==
                                              ThemeMode.dark
                                          ? AppColors.lightPrimary
                                          : AppColors.darkPrimary),
                                  title: Text(
                                    "Strategies",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: themeManager.themeMode ==
                                              ThemeMode.dark
                                          ? AppColors
                                              .lightPrimary // Text color for dark mode
                                          : AppColors
                                              .darkPrimary, // Text color for light mode
                                    ),
                                  ),
                                  children: [
                                    _buildSubListTile("Subscribed", onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Subcribed(),
                                          settings: RouteSettings(),
                                          fullscreenDialog: false,
                                        ),
                                      );
                                    }),
                                    _buildSubListTile("Deployed", onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Deployed(),
                                          settings: RouteSettings(),
                                          fullscreenDialog: false,
                                        ),
                                      );
                                    }),
                                    _buildSubListTile("Marketplace", onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MarketPlace(),
                                          settings: RouteSettings(),
                                          fullscreenDialog: false,
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                                _buildListTile(
                                    Icons.account_balance, "PaperTrade",
                                    onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PaperTrade(),
                                      settings: RouteSettings(),
                                      fullscreenDialog: false,
                                    ),
                                  );
                                }),
                                _buildListTile(Icons.manage_accounts_rounded,
                                    "ManageBroker", onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ManageBroker(),
                                      settings: RouteSettings(),
                                      fullscreenDialog: false,
                                    ),
                                  );
                                }),
                                Padding(
                                  padding: const EdgeInsets.only(left: 15),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .spaceBetween, // Distribute space between the items
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                themeManager.themeMode ==
                                                        ThemeMode.dark
                                                    ? Icons.dark_mode
                                                    : Icons.light_mode,
                                                color: themeManager.textColor,
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 15),
                                                child: Text(
                                                  "Change Theme",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: themeManager
                                                                .themeMode ==
                                                            ThemeMode.dark
                                                        ? Colors
                                                            .white // Text color for dark mode
                                                        : Colors
                                                            .black, // Text color for light mode
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 15),
                                            child: Switch(
                                              value: themeManager.themeMode ==
                                                  ThemeMode.dark,
                                              onChanged: (bool value) {
                                                themeManager.toggleTheme();
                                              },
                                              activeColor:
                                                  AppColors.lightPrimary,
                                              inactiveTrackColor:
                                                  Colors.grey[800],
                                              activeTrackColor:
                                                  AppColors.yellow,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: ElevatedButton(
                                    onPressed: () => logout(context),
                                    child: Text(
                                      'Logout',
                                      style: TextStyle(
                                          color: themeManager.themeMode ==
                                                  ThemeMode.dark
                                              ? Colors.white
                                              : AppColors.lightPrimary),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Center(
                                child: Text("No data found from backend"));
                          }
                        },
                      );
                    } else {
                      return Center(child: Text("No email found"));
                    }
                  },
                ),
              ),
            )));
  }

  Widget _buildListTile(IconData icon, String title, {VoidCallback? onTap}) {
    final themeManager = Provider.of<ThemeManager>(context);

    return ListTile(
      leading: Icon(icon,
          color: themeManager.themeMode == ThemeMode.dark
              ? AppColors.lightPrimary
              : AppColors.darkPrimary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: themeManager.themeMode == ThemeMode.dark
              ? AppColors.lightPrimary // Text color for dark mode
              : AppColors.darkPrimary, // Text color for light mode
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSubListTile(String title, {VoidCallback? onTap}) {
    final themeManager = Provider.of<ThemeManager>(context);

    return Padding(
      padding: const EdgeInsets.only(left: 55),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: themeManager.themeMode == ThemeMode.dark
                ? AppColors.lightPrimary
                : AppColors.darkPrimary,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
