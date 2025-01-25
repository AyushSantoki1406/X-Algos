import 'package:flutter/material.dart';
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

class MyAccountPage extends StatelessWidget {
  Future<void> logout(BuildContext context) async {
    // Clear user data (e.g., SharedPreferences)
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();

    await secureStorage.deleteAll();

    // Set 'isLoggedIn' to false
    await prefs.setBool('isLoggedIn', false);

    // Print the updated value
    bool? isLoggedIn = prefs.getBool('isLoggedIn');
    print('Is Logged In: $isLoggedIn'); // Output: false

    // Navigate to SplashScreen
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
      body: ListView(
        children: [
          // Header section
          ListTile(
            title: Text(
              "ha****@****.com",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("User ID: 94081645"),
            trailing: Icon(Icons.verified, color: Colors.green),
          ),
          Divider(),

          // Dashboard
          _buildListTile(
            Icons.settings,
            "Dashboard",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Home()),
              );
            },
          ),

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
                    MaterialPageRoute(builder: (context) => LiveTrade()),
                  );
                },
              ),
              _buildSubListTile(
                "Executed Trade",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ExecutedTrade()),
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
                    MaterialPageRoute(builder: (context) => Subcribed()),
                  );
                },
              ),
              _buildSubListTile(
                "Deployed",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Deployed()),
                  );
                },
              ),
              _buildSubListTile(
                "Marketplace",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MarketPlace()),
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
                MaterialPageRoute(builder: (context) => PaperTrade()),
              );
            },
          ),
          _buildListTile(
            Icons.share,
            "Manage Broker",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageBroker()),
              );
            },
          ),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => logout(context), // Pass context explicitly
              child: Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to create ListTile
  Widget _buildListTile(IconData icon, String title,
      {Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title),
      trailing: trailing,
      onTap: onTap,
    );
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
}
