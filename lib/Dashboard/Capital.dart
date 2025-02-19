import 'dart:math';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shimmer/main.dart';
import 'package:xalgo/Dashboard/DashboardAngel.dart';
import 'package:xalgo/ErrorPages/ErrorPage.dart';
import 'package:xalgo/ErrorPages/NoData.dart';
import 'package:xalgo/SplashScreen.dart';
import 'package:xalgo/main.dart';
import 'package:xalgo/widgets/drawer_widget.dart';
import 'package:provider/provider.dart';
import 'package:xalgo/theme/theme_manage.dart';
import 'package:xalgo/theme/app_colors.dart';
import 'package:xalgo/secret/secret.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';
import 'package:xalgo/ErrorPages/ErrorPage.dart' as errorPage;
import 'package:xalgo/ErrorPages/NoData.dart' as noData;
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:xalgo/Indicator/ice_cream_indicator.dart';

final GlobalKey<CapitalState> _capitalKey = GlobalKey<CapitalState>();

class Capital extends StatefulWidget {
  const Capital({super.key});

  @override
  CapitalState createState() => CapitalState();
}

class CapitalState extends State<Capital> {
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  double sum = 0;

  bool brokerLogin1 = false;
  List<dynamic> capital = [];
  bool isLoading = false;
  bool loader = false;
  List<dynamic> newCapital = [];

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

  Future<void> fetchData() async {
    if (!mounted) return;
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      String? email = await getEmail();

      final profileResponse = await http.post(
        Uri.parse('${Secret.backendUrl}/userinfo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'Email': email}),
      );

      if (profileResponse.statusCode == 200) {
        await secureStorage.write(
            key: 'allClientData', value: profileResponse.body);
      } else {
        throw Exception("Failed to fetch user info: ${profileResponse.body}");
      }

      // Fetch DB Schema
      final dbschemaResponse = await http.post(
        Uri.parse('${Secret.backendUrl}/dbSchema'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'Email': email}),
      );

      if (dbschemaResponse.statusCode == 200) {
        var decodedData = jsonDecode(dbschemaResponse.body);

        if (decodedData is Map<String, dynamic>) {
          await secureStorage.write(
              key: 'userSchema', value: dbschemaResponse.body);
        } else {
          throw Exception("Unexpected response format from dbSchema API.");
        }
      } else if (dbschemaResponse.statusCode == 403) {
        throw Exception("Access denied (403) while fetching dbSchema.");
      } else {
        throw Exception("Failed to fetch dbSchema: ${dbschemaResponse.body}");
      }

      // Read stored user schema
      String? userSchemaString = await secureStorage.read(key: 'userSchema');
      if (userSchemaString != null) {
        Map<String, dynamic> userSchema = jsonDecode(userSchemaString);
        int brokerCount =
            int.tryParse(userSchema['BrokerCount'].toString()) ?? 0;
        brokerLogin1 = brokerCount > 0;

        await secureStorage.write(
            key: 'BrokerCount', value: brokerLogin1.toString());
      }

      if (brokerLogin1) {
        try {
          final brokerResponse = await http.post(
            Uri.parse('${Secret.backendUrl}/addbroker'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'First': false,
              "Email": email,
              "userSchema": userSchemaString
            }),
          );

          if (brokerResponse.statusCode == 200) {
            final brokerData = jsonDecode(brokerResponse.body);
            List<dynamic> brokerList = (brokerData as List)
                .map((user) => user['userData']['data'])
                .toList();

            double newSum = 0;
            for (var item in brokerList) {
              newSum += double.tryParse(item['net']?.toString() ?? '0') ?? 0.0;
            }

            if (mounted) {
              setState(() {
                sum = newSum;
                newCapital = brokerList;
                isLoading = false;
              });
            }
          } else {
            throw Exception(
                "Failed to fetch broker data: ${brokerResponse.body}");
          }
        } catch (e) {
          print("Error in capital to fetch addbroker $e");
        } finally {
          setState(() => isLoading = false); // Stop loader after request
        }
      } else {
        // Fetch client data
        String? clientDataString =
            await secureStorage.read(key: 'allClientData');
        if (clientDataString != null) {
          List<dynamic> clientData = jsonDecode(clientDataString);

          double localSum = 0;
          for (var item in clientData) {
            if (item['userData'] != null) {
              localSum += double.tryParse(
                      item['capital']?[0]?['net']?.toString() ?? '0') ??
                  0.0;
            } else {
              localSum += double.tryParse(item['balances']?['result']?[0]
                              ?['balance_inr']
                          ?.toString() ??
                      '0') ??
                  0.0;
            }
          }

          if (mounted) {
            setState(() {
              sum = localSum;
              isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print("Error in fetchData(): $e");

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeProvider>(context);
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchProfile(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const errorPage.Errorpage();
          } else if (!snapshot.hasData) {
            return const noData.Nodata();
          } else if (snapshot.hasData) {
            final data = snapshot.data!;
            return
                //  CustomRefreshIndicator(
                //   onRefresh: () async {
                //     await fetchData();
                //   },
                //   builder: (context, child, controller) {
                //     return Stack(
                //       children: [
                //         child, // Main content stays below the indicator

                //         // Custom Indicator positioned under the AppBar
                //         AnimatedBuilder(
                //           animation: controller,
                //           builder: (context, _) {
                //             double indicatorHeight = (controller.value * 80)
                //                 .clamp(0.0, 80.0); // Adjust max height

                //             return Container(
                //               height:
                //                   indicatorHeight, // Dynamic height based on pull
                //               width: double.infinity,
                //               decoration: BoxDecoration(
                //                 color: Colors.pinkAccent, // Indicator color
                //                 borderRadius: BorderRadius.vertical(
                //                   bottom: Radius.circular(500), // Rounded bottom
                //                 ),
                //               ),
                //               alignment: Alignment.center,
                //               child: Opacity(
                //                 opacity: controller.value.clamp(0.0, 1.0),
                //                 child: Icon(
                //                   Icons.icecream,
                //                   size: 40,
                //                   color: Colors.white,
                //                 ),
                //               ),
                //             );
                //           },
                //         ),
                //       ],
                //     );
                //   },
                CustomMaterialIndicator(
              onRefresh: () async {
                await fetchData();
              },
              backgroundColor: Colors.white,
              indicatorBuilder: (context, controller) {
                return Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: CircularProgressIndicator(
                    color: AppColors.yellow,
                    value: controller.state.isLoading
                        ? null
                        : math.min(controller.value, 1.0),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.all(0),
                margin: EdgeInsets.all(0),
                width: double.infinity,
                color: themeManager.isDarkMode
                    ? AppColors.darkPrimary
                    : AppColors.lightPrimary,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Change this line
                    children: [
                      Card(
                        color: themeManager.isDarkMode
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0), // Simplified padding
                                child: Column(
                                  mainAxisSize: MainAxisSize
                                      .min, // Prevent taking extra height
                                  children: [
                                    Text(
                                      "P&L",
                                      style: TextStyle(
                                          color: themeManager.isDarkMode ==
                                                  ThemeMode.dark
                                              ? AppColors.darkText
                                              : AppColors.lightText),
                                    ),
                                    Text("₹",
                                        style: TextStyle(
                                            color: themeManager.isDarkMode ==
                                                    ThemeMode.dark
                                                ? AppColors.darkText
                                                : AppColors.lightText)),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0), // Simplified padding
                                child: Column(
                                  mainAxisSize: MainAxisSize
                                      .min, // Prevent taking extra height
                                  children: [
                                    Text(
                                      "Capital",
                                      style: TextStyle(
                                          color: themeManager.isDarkMode ==
                                                  ThemeMode.dark
                                              ? AppColors.darkText
                                              : AppColors.lightText),
                                    ),
                                    isLoading
                                        ? Column(
                                            children: [
                                              SizedBox(height: 5),
                                              const SizedBox(
                                                height: 15,
                                                width: 15,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors.yellow,
                                                ),
                                              )
                                            ],
                                          )
                                        : Text(
                                            '₹${sum.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: sum < 0
                                                  ? Colors.red
                                                  : Colors.green,
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
                      SizedBox(height: 0), // Ensure there's no spacing
                      Flexible(
                        child: Container(
                          margin: EdgeInsets.zero, // No margin
                          padding: EdgeInsets.zero, // No padding
                          color: Colors
                              .transparent, // Ensure background is transparent
                          child: DashboardAngel(
                            capital: newCapital,
                            darkMode: themeManager.isDarkMode,
                          ),
                        ),
                      )
                    ],
                  ),
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
      ),
    );
  }
}
