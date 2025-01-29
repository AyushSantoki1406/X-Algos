import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:xalgo/widgets/drawer_widget.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class MarketPlace extends StatefulWidget {
  const MarketPlace({super.key});

  @override
  State<MarketPlace> createState() => _MarketPlaceState();
}

class _MarketPlaceState extends State<MarketPlace> {
  List<dynamic> strategyData = [];
  List<String> subscribedStrategies = [];
  Map<String, dynamic> userSchema = {}; // Fixed type
  bool isLoading = true;
  final String url = "https://oyster-app-4y3eb.ondigitalocean.app";
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  String? selectedStrategyId; // Fixed
  String? selectedDropDownValue;
  List<String> dropDownItems = [];

  Future<String?> getEmail() async {
    try {
      String? userEmail = await secureStorage.read(key: 'Email');
      print('Email>>>>>>>>>>:$userEmail');
      return userEmail;
    } catch (e) {
      print('Error retrieving email:$e');
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    String? email = await getEmail();
    try {
      final response = await http.post(
        Uri.parse('$url/getMarketPlaceData'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          strategyData = data['allData'];
          subscribedStrategies =
              List<String>.from(data['SubscribedStrategies']);
          userSchema = Map<String, dynamic>.from(data['userSchema']); // Fixed
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching data:$e');
    }
  }

  Future<void> handleSubscribe(String strategyId) async {
    String? email = await getEmail();
    print(strategyId);

    try {
      final response = await http.post(
        Uri.parse('$url/updateSubscribe'),
        body: jsonEncode({
          'strategyId':
              int.tryParse(strategyId) ?? strategyId, // Ensure correct type
          'email': email,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          strategyData = strategyData.map((strategy) {
            if (strategy['_id'] == strategyId) {
              return {
                ...strategy,
                'subscribeCount':
                    int.tryParse(data['newSubscribeCount'].toString()) ??
                        data['newSubscribeCount'],
              };
            }
            return strategy;
          }).toList();

          subscribedStrategies =
              List<String>.from(data['SubscribedStrategies']);
        });
      } else {
        print("Failed to update subscription: ${response.body}");
      }
    } catch (error) {
      print("Error updating subscribe count: $error");
    }
  }

  // Function to set the dropdown items
  void setDropDownIds(List<String> filteredAliases) {
    setState(() {
      dropDownItems = filteredAliases; // Update the dropdown items
    });
  }

  void handleOpen(String strategyId) {
    print(strategyId);
    setState(() {
      selectedStrategyId = strategyId;
    });

    final List deployedData = (userSchema['DeployedData'] as List?) ?? [];
    final List brokerIds = (userSchema['BrokerIds'] as List?) ?? [];
    final Map<String, dynamic> accountAliases =
        (userSchema['AccountAliases'] as Map<String, dynamic>?) ?? {};

    final matchingAccounts = deployedData
        .where((deployed) =>
            deployed is Map<String, dynamic> &&
            deployed['Strategy'] == strategyId)
        .map((deployed) => deployed['Account'])
        .toList();

    print("Matching Accounts: $matchingAccounts");

    final filteredBrokerIds = brokerIds
        .where((brokerId) => !matchingAccounts.contains(brokerId))
        .toList();

    print("Filtered Broker IDs: $filteredBrokerIds");

    final List<String> filteredAliases = filteredBrokerIds
        .map((brokerId) =>
            accountAliases[brokerId]?.toString() ?? brokerId.toString())
        .toList(); // Ensure List<String>

    print("Filtered Aliases: $filteredAliases");

    setDropDownIds(filteredAliases);
    showBrokerSelectionModal(context, filteredAliases);
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Market Place',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50), // Circular placeholder
            child: Image.asset(
              'assets/images/darklogo.png', // Replace with your image path
              fit: BoxFit.cover,
            ),
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      drawer: AppDrawer(), // Optional: left drawer
      endDrawer: AppDrawer(), // Right drawer (End drawer)
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: strategyData.length,
              itemBuilder: (context, index) {
                final strategy =
                    strategyData[index]; // Ensure strategy is defined here
                bool isSubscribed =
                    subscribedStrategies.contains(strategy['_id']);
                return Container(
                  padding: EdgeInsets.all(16),
                  color: Color(0xFF000000),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, top: 8, bottom: 8),
                    child: Container(
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Section
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        child: Image.asset(
                                          'assets/images/strategie_img.png',
                                          height: 40,
                                          width: 40,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            strategy['title'],
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Strategy: ${strategy['strategyType']}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          // Add any other Text or widget children here...
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 4),

                              // Capital Info
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Text(
                                      "Capital Requirement:",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      strategy['capitalRequirement'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 4),

                              // Strategy Description
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  strategy['description'],
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white),
                                ),
                              ),

                              const SizedBox(height: 4),

                              // Execution Info
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Card(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          Text(
                                            "✍️  Created By: ${strategy['createdBy']}",
                                            style: TextStyle(fontSize: 13),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Card(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          Text(
                                            "📅  Created on: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(strategy['dateOfCreation']))}",
                                            style: TextStyle(fontSize: 13),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.all(0),
                                    child: SizedBox(
                                        height: 40,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // First child with half the width
                                            Expanded(
                                              child: Card(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        "👥  Subscriber: ${strategy['subscribeCount']}",
                                                        style: TextStyle(
                                                            fontSize: 13),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Second child with half the width
                                            Expanded(
                                              child: Card(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        "🚀  Deployed: ${strategy['deployedCount']}",
                                                        style: TextStyle(
                                                            fontSize: 13),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )),
                                  ),
                                  SizedBox(height: 8),
                                  Card(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          Text(
                                            "🕒  All Days at ${strategy['time']}",
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 4),

                              // Footer Section
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  height: 40, // Define a height for the Row
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: isSubscribed
                                              ? null // Disable the button if subscribed
                                              : () => handleSubscribe(strategy[
                                                  '_id']), // Pass strategy['_id'] if not subscribed
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isSubscribed
                                                ? Colors.grey
                                                : Colors
                                                    .green, // Change color when disabled
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                          ),
                                          child: Text(isSubscribed
                                              ? "Subscribed"
                                              : "Subscribe"),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: isSubscribed
                                              ? () =>
                                                  handleOpen(strategy['_id'])
                                              : null, // Pass strategy['_id']
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isSubscribed
                                                ? Colors.blue
                                                : Colors.grey,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                          ),
                                          child: const Text("Deploy"),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void showBrokerSelectionModal(
      BuildContext context, List<String> filteredAliases) {
    setDropDownIds(filteredAliases); // Set dropdown items to filtered aliases

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // To allow full control of height
      backgroundColor: Colors
          .transparent, // Make the background transparent for custom style
      builder: (context) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: 300, // Set custom height here
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title Text
                          Text(
                            "Select a Broker",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 10),
                          // Dropdown Button
                          DropdownButton<String>(
                            value: selectedDropDownValue,
                            hint: Text("Select Broker"),
                            onChanged: (String? newValue) {
                              setModalState(() {
                                selectedDropDownValue = newValue;
                              });
                            },
                            items: dropDownItems.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 20),
                          // Confirm Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              // primary: Colors.blueAccent, // Button color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context); // Close the modal
                              print("Selected Broker: $selectedDropDownValue");
                            },
                            child: Text(
                              "Confirm",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.black87,
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Close the modal when clicked
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
