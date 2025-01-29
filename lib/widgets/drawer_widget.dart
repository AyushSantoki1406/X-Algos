import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xalgo/Deployed.dart';
import 'package:xalgo/ExecutedTrade.dart';
import 'package:xalgo/HomePage.dart';
import 'package:xalgo/LiveTrade.dart';
import 'package:xalgo/ManageBroker.dart';
import 'package:xalgo/Marketplace.dart';
import 'package:xalgo/PaperTrade.dart';
import 'package:xalgo/Subcribed.dart';
import 'package:xalgo/main.dart'; // Ensure SplashScreen is defined or imported
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

void main() => runApp(AppDrawer());

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
  // Method to fetch email from secure storage
  Future<String?> getEmail() async {
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();
    try {
      String? userEmail = await secureStorage.read(key: 'Email');
      // print('Email retrieved from storage: $userEmail');
      return userEmail;
    } catch (e) {
      // print('Error retrieving email: $e');
    }
    return null;
  }

  // Method to call backend route and send the email
  Future<String?> callBackendRoute(String email) async {
    final url =
        Uri.parse('https://oyster-app-4y3eb.ondigitalocean.app/dbschema');

    try {
      final response = await http.post(
        url,
        body: json.encode({'Email': email}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Parse the response body into a Dart map
        final responseBody = jsonDecode(response.body);

        // Access XalgoID from the parsed response
        final String? algoID = responseBody['XalgoID'];
        // print('Backend response XalgoID: $algoID');

        // Return the XalgoID
        return algoID;
      } else {
        // print('Failed to call backend. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // print('Error calling backend: $e');
      return null;
    }
  }

  // Logout method
  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();

    await secureStorage.deleteAll();
    await prefs.setBool('isLoggedIn', false);

    bool? isLoggedIn = prefs.getBool('isLoggedIn');
    // print('Is Logged In: $isLoggedIn');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SplashScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Account"),
        leading: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Home()),
            );
          },
          child: Icon(Icons.arrow_back),
        ),
      ),
      body: FutureBuilder<String?>(
        future: getEmail(),
        builder: (context, snapshot) {
          // print('Snapshot data: ${snapshot.data}');
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            String email = snapshot.data!;
            // Call backend route and pass the email
            return FutureBuilder<String?>(
              future: callBackendRoute(email),
              builder: (context, backendSnapshot) {
                if (backendSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (backendSnapshot.hasError) {
                  return Center(
                      child: Text(
                          "Error calling backend: ${backendSnapshot.error}"));
                } else if (backendSnapshot.hasData) {
                  String? algoID = backendSnapshot.data;
                  return ListView(
                    children: [
                      ListTile(
                        title: Text("$email",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("User ID: $algoID"),
                      ),
                      Divider(),

                      // Dashboard
                      _buildListTile(Icons.settings, "Dashboard", onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Home()),
                        );
                      }),

                      // Order ExpansionTile
                      ExpansionTile(
                        leading: Icon(Icons.person, color: Colors.white),
                        title: Text("Order"),
                        children: [
                          _buildSubListTile(
                            "Live Trade",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LiveTradePage()),
                              );
                            },
                          ),
                          _buildSubListTile(
                            "Executed Trade",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ExecutedTrade()),
                              );
                            },
                          ),
                        ],
                      ),

                      // Strategies ExpansionTile
                      ExpansionTile(
                        leading: Icon(Icons.analytics, color: Colors.white),
                        title: Text("Strategies"),
                        children: [
                          _buildSubListTile(
                            "Subscribed",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Subcribed()),
                              );
                            },
                          ),
                          _buildSubListTile(
                            "Deployed",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Deployed()),
                              );
                            },
                          ),
                          _buildSubListTile(
                            "Marketplace",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MarketPlace()),
                              );
                            },
                          ),
                        ],
                      ),

                      // Other menu options
                      _buildListTile(
                        Icons.account_balance,
                        "Paper Trade",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PaperTrade()),
                          );
                        },
                      ),
                      _buildListTile(
                        Icons.share,
                        "Manage Broker",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ManageBroker()),
                          );
                        },
                      ),

                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: () => logout(context),
                          child: Text('Logout'),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Center(child: Text("No data found from backend"));
                }
              },
            );
          } else {
            return Center(child: Text("No email found"));
          }
        },
      ),
    );
  }

  // Helper method to create ListTile
  Widget _buildListTile(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title),
      onTap: onTap,
    );
  }
}

// Helper method to create sub-items in ExpansionTile
Widget _buildSubListTile(String title, {VoidCallback? onTap}) {
  return Padding(
    padding: const EdgeInsets.only(left: 55),
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      onTap: onTap,
    ),
  );
}
