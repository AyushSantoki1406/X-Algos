import 'package:flutter/material.dart';
import 'package:xalgo/Deployed.dart';
import 'package:xalgo/ExecutedTrade.dart';
import 'package:xalgo/HomePage.dart';
import 'package:xalgo/LiveTrade.dart';
import 'package:xalgo/ManageBroker.dart';
import 'package:xalgo/Marketplace.dart';
import 'package:xalgo/PaperTrade.dart';
import 'package:xalgo/Subcribed.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Account"),
        leading: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      Home()), // Replace `Home` with your desired screen.
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
          // List items with dropdown
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
          ExpansionTile(
              leading: Icon(Icons.person, color: Colors.white),
              title: Text("Order"),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide.none,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide.none,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 55),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        visualDensity: VisualDensity(
                            horizontal: 0,
                            vertical: -4), // Remove vertical space
                        contentPadding:
                            EdgeInsets.zero, // No padding around the tile
                        title: Text("Live Trade"),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LiveTrade()),
                          );
                        },
                      ),
                      ListTile(
                        visualDensity: VisualDensity(
                            horizontal: 0,
                            vertical: -4), // Remove vertical space
                        contentPadding:
                            EdgeInsets.zero, // No padding around the tile
                        title: Text("Executed Trade"),
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
                ),
              ]),
          ExpansionTile(
            leading: Icon(Icons.analytics, color: Colors.white),
            title: Text("Strategies"),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide.none,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide.none,
            ),
            children: [
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align content to the left
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 55),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          visualDensity: VisualDensity(
                              horizontal: 0,
                              vertical: -4), // Remove vertical space
                          contentPadding:
                              EdgeInsets.zero, // No padding around the tile
                          title: Text("Subcribed"),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Subcribed()),
                            );
                          },
                        ),
                        ListTile(
                          visualDensity: VisualDensity(
                              horizontal: 0,
                              vertical: -4), // Remove vertical space
                          contentPadding:
                              EdgeInsets.zero, // No padding around the tile
                          title: Text("Deployed"),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Deployed()),
                            );
                          },
                        ),
                        ListTile(
                          visualDensity: VisualDensity(
                              horizontal: 0,
                              vertical: -4), // Remove vertical space
                          contentPadding:
                              EdgeInsets.zero, // No padding around the tile
                          title: Text("MarketPlace"),
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
                  ),
                ],
              ),
            ],
          ),
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
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title,
      {Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title),
      trailing: trailing,
      onTap: onTap, // Adds the onTap functionality
    );
  }
}
