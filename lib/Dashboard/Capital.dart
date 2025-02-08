import 'dart:math';

import 'package:dio/dio.dart';
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

class Capital extends StatefulWidget {
  const Capital({super.key});

  @override
  State<Capital> createState() => _CapitalState();
}

class _CapitalState extends State<Capital> {
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  double sum = 0;

  bool brokerLogin1 = false;
  List<dynamic> capital = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  //function for gmail
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
          print('No user schema found in storage.');
        }
      } catch (e) {
        print('Error loading user schema: $e');
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

  //main function
  void fetchData() async {
    isLoading = true;
    try {
      String? email = await getEmail();

      ///////////////userinfo stored
      final profileData = await http.post(
          Uri.parse('${Secret.backendUrl}/userinfo'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'Email': email}));
      final data = profileData.body;
      print(
          "profile data is fetched DASHBOARD(Capital)>>>>>>>>>>>>>>>>>>>>>>>>>");

      await secureStorage.write(key: 'allClientData', value: data);

      ////////////////////store dbschema
      final dbschema = await http.post(
          Uri.parse('${Secret.backendUrl}/dbSchema'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'Email': email}));

      final data2 = dbschema.body;
      print(
          "dbschema data is fetched DASHBOARD(Capital)>>>>>>>>>>>>>>>>>>>>>>>>>");

      await secureStorage.write(key: 'userSchema', value: data2);

      String? userSchemaString = await secureStorage.read(key: 'userSchema');

      if (userSchemaString != null) {
        Map<String, dynamic> userSchema = jsonDecode(userSchemaString);

        int brokerCount = (userSchema['BrokerCount'] is int)
            ? userSchema['BrokerCount']
            : int.tryParse(userSchema['BrokerCount'].toString()) ?? 0;
        print("finding Broker Count is true or false DASHBOARD(Capital)");
        if (brokerCount > 0) {
          await secureStorage.write(key: 'BrokerCount', value: 'true');
          brokerLogin1 = true;
        } else {
          await secureStorage.write(key: 'BrokerCount', value: 'false');
          brokerLogin1 = false;
        }
      } else {
        print('No user schema found');
      }

      String? brokerCountStr = await secureStorage.read(key: 'BrokerCount');

      if (brokerLogin1) {
        final response = await http.post(
          Uri.parse('${Secret.backendUrl}/addbroker'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(
              {'First': false, "Email": email, "userSchema": userSchemaString}),
        );

        final a = jsonDecode(response.body);

        List<dynamic> newCapital =
            (a as List).map((user) => user['userData']['data']).toList();

        double newSum = 0;

        for (var item in newCapital) {
          newSum += double.tryParse(item['net']?.toString() ?? '0') ?? 0.0;
        }

        setState(() {
          sum = newSum;
        });

        print("Get sum in if part in DASHBOARD(Capital)${sum}");
        await secureStorage.write(key: 'userSchema', value: userSchemaString);
      } else {
        String? clientDataString =
            await secureStorage.read(key: 'allClientData');

        if (clientDataString != null) {
          List<dynamic> clientData = jsonDecode(clientDataString);

          for (int index = 0; index < clientData.length; index++) {
            var item = clientData[index];

            if (item['userData'] != null) {
              sum += double.tryParse(
                      item['capital']?[index]?['net']?.toString() ?? '0') ??
                  0.0;
            } else {
              sum += double.tryParse(item['balances']?['result']?[0]
                              ?['balance_inr']
                          ?.toString() ??
                      '0') ??
                  0.0;
            }
          }
          print("Get sum in else part in DASHBOARD(Capital)${sum}");
        }
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return Scaffold(
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
            prefs.setBool('isprintgedIn', false);

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
                            padding: const EdgeInsets.only(left: 8.0, right: 8),
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
                            padding: const EdgeInsets.only(left: 8.0, right: 8),
                            child: Column(
                              children: [
                                Text(
                                  "Capital",
                                  style: TextStyle(
                                      color: themeManager.themeMode ==
                                              ThemeMode.dark
                                          ? AppColors.lightPrimary
                                          : AppColors.darkPrimary),
                                ),
                                isLoading
                                    ? Column(
                                        children: [
                                          SizedBox(height: 5),
                                          const SizedBox(
                                            height: 15,
                                            width: 15,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.yellow,
                                            ),
                                          ) // Show loader when isLoading is true
                                        ],
                                      )
                                    : Text(
                                        '₹${sum.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: sum < 0
                                              ? Colors.red
                                              : Colors
                                                  .green, // Change text color
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
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
          return Container();
        }
      },
    ));
  }
}
