import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:xalgo/secret/secret.dart';
import 'package:xalgo/widgets/drawer_widget.dart';
import 'package:provider/provider.dart';
import 'package:xalgo/theme/theme_manage.dart';
import 'package:xalgo/theme/app_colors.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ExecutedTrade extends StatefulWidget {
  const ExecutedTrade({super.key});

  @override
  State<ExecutedTrade> createState() => _ExecutedTradeState();
}

class _ExecutedTradeState extends State<ExecutedTrade> {
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  String? email;
  String? XID;
  Map<String, dynamic>? userSchema;

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchIDs();
  }

  void fetchData() async {
    try {
      email = await secureStorage.read(key: 'Email').toString();
      var data = await secureStorage.read(key: 'userSchema');
      userSchema = jsonDecode(data.toString());
      print("here is user email ........${userSchema?['Email']}");
    } catch (e) {
      print(e);
    }
  }

  void fetchIDs() async {
    try {
      var response = await http.post(
        Uri.parse('${Secret.backendUrl}/'),
        body: json.encode({'Email': email}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeProvider>(context);
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    return WillPopScope(
        onWillPop: () async => false, // Prevents back button navigation
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
                      'Executed Trade',
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
                body: const Center(
                  child: Text("ExecutedTrade Page Content   Here!"),
                ),
              ),
            )));
  }
}
