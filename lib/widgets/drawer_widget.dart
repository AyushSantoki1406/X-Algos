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
import 'package:xalgo/main.dart';

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
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  Future<String?> getEmail() async {
    try {
      return await secureStorage.read(key: 'Email');
    } catch (e) {
      return null;
    }
  }

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
        final responseBody = jsonDecode(response.body);
        return responseBody['XalgoID'];
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await secureStorage.deleteAll();
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SplashScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("My Account"),
          leading: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Home(),
                  settings: RouteSettings(), // Required for popGestureEnabled
                  fullscreenDialog: false,
                ),
              );
            },
            child: Icon(Icons.arrow_back),
          ),
        ),
        body: FutureBuilder<String?>(
          future: getEmail(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (snapshot.hasData) {
              String email = snapshot.data!;
              return FutureBuilder<String?>(
                future: callBackendRoute(email),
                builder: (context, backendSnapshot) {
                  if (backendSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (backendSnapshot.hasError) {
                    return Center(
                        child: Text("Error: ${backendSnapshot.error}"));
                  } else if (backendSnapshot.hasData) {
                    String? algoID = backendSnapshot.data;
                    return ListView(
                      children: [
                        ListTile(
                          title: Text(
                            "$email",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("UserID: $algoID"),
                        ),
                        Divider(),
                        _buildListTile(Icons.settings, "Dashboard", onTap: () {
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
                          leading: Icon(Icons.person, color: Colors.white),
                          title: Text("Order"),
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
                            _buildSubListTile("ExecutedTrade", onTap: () {
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
                          leading: Icon(Icons.analytics, color: Colors.white),
                          title: Text("Strategies"),
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
                        _buildListTile(Icons.account_balance, "PaperTrade",
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
                        _buildListTile(Icons.share, "ManageBroker", onTap: () {
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
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title),
      onTap: onTap,
    );
  }

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
}
