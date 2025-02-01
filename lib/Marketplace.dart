import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:xalgo/app_colors.dart';
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
  Map<String, dynamic> userSchema =
      {}; // Map<String, dynamic> for handling dynamic data
  bool isLoading = true;
  final String url = "https://oyster-app-4y3eb.ondigitalocean.app";
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  String? selectedStrategyId;
  List<String> dropDownItems = [];
  String? selectedDropDownValue;

  String quaninty = "";
  String index = "";
  String account = "";

  Future<String?> getEmail() async {
    try {
      String? userEmail = await secureStorage.read(key: 'Email');
      print('Email>>>>>>>>>>:$userEmail');
      return userEmail;
    } catch (e) {
      print('Error retrieving email: $e');
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
          userSchema = Map<String, dynamic>.from(data['userSchema']);
          print(subscribedStrategies);
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> handleSubscribe(String strategyId) async {
    String? email = await getEmail();
    print(strategyId);
    try {
      final response = await http.post(
        Uri.parse('$url/updateSubscribe'),
        body: jsonEncode({
          'strategyId': int.tryParse(strategyId) ?? strategyId,
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
                        data['newSubscribeCount']
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
    print("MatchingAccounts: $matchingAccounts");
    final filteredBrokerIds = brokerIds
        .where((brokerId) => !matchingAccounts.contains(brokerId))
        .toList();
    print("FilteredBrokerIDs: $filteredBrokerIds");
    final List<String> filteredAliases = filteredBrokerIds
        .map((brokerId) =>
            accountAliases[brokerId]?.toString() ?? brokerId.toString())
        .toList();
    print("FilteredAliases: $filteredAliases");
    setDropDownIds(filteredAliases);
    showBrokerSelectionModal(context, filteredAliases);
  }

  void handleInputChange(String value, String field) {
    if (field == "Quaninty") {
      setState(() {
        quaninty = value; // Update your Quaninty variable here
      });
    } else if (field == "Index") {
      setState(() {
        index = value; // Update your Index variable here
      });
    } else if (field == "Account") {
      setState(() {
        account = value; // Update your Account variable here
      });
    }
  }

  Future<void> handleDeploy() async {
    String? email = await getEmail();
    print("asdfghjk");
    try {
      setState(() {
        isLoading = true; // Start loading
      });
      String? findKeyByValue(Map<String, dynamic> map, String value) {
        return map.entries
            .firstWhere((entry) => entry.value == value,
                orElse: () => MapEntry('', ''))
            .key;
      }

      // Ensure to handle Account safely
      String? a = findKeyByValue(
          userSchema['AccountAliases'] as Map<String, dynamic>, account);
      print(a);
      print(selectedStrategyId); // Sending a POST request
      final response = await http.post(
        Uri.parse('$url/addDeployed'),
        body: json.encode({
          'Email': email,
          'selectedStrategyId': selectedStrategyId,
          'Index': 1, // Example value
          'Quaninty': 100, // Example value
          'a': a,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        print(responseData);
        // Mock dispatch call (you need a state management approach like Provider or Bloc)
        // dispatch(userSchemaRedux(responseData));
        // dispatch(allClientData(profileData.data));
        // Show alert (using a simple dialog for example)
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Text("Successfully added"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("OK"),
              ),
            ],
          ),
        );
        setState(() {
          isLoading = false;
        });
      } else {
        print("Failed to deploy: ${response.statusCode}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    } finally {
      setState(() {
        Navigator.pop(context);
        isLoading = false; // Stop loading on error
      });
    }
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
          ? Center(
              child: CircularProgressIndicator(
              color: Colors.amber,
            ))
          : PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {},
              child: ListView.builder(
                itemCount: strategyData.length,
                itemBuilder: (context, index) {
                  final strategy =
                      strategyData[index]; // Ensure strategy is defined here
                  bool isSubscribed =
                      subscribedStrategies.contains(strategy['_id']);
                  return Container(
                    padding: EdgeInsets.all(16),
                    color: Color.fromARGB(255, 19, 19, 19),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, top: 8, bottom: 8),
                      child: Container(
                        child: Card(
                          color: Color.fromARGB(255, 25, 25, 25),
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
                                  color: Color.fromARGB(255, 25, 25, 25),
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
                                      color: Color.fromARGB(255, 25, 25, 25),
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
                                      color: Color.fromARGB(255, 25, 25, 25),
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
                                                  color: Color.fromARGB(
                                                      255, 25, 25, 25),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
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
                                                  color: Color.fromARGB(
                                                      255, 25, 25, 25),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
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
                                      color: Color.fromARGB(255, 25, 25, 25),
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
                                                  ? Color.fromARGB(
                                                      255, 25, 25, 25)
                                                  : Colors.grey,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                side: isSubscribed
                                                    ? BorderSide(
                                                        color: Colors.white,
                                                        width: 1)
                                                    : BorderSide(
                                                        color:
                                                            Colors.transparent,
                                                        width: 0),
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
            ),
    );
  }

  void showBrokerSelectionModal(
      BuildContext context, List<String> filteredAliases) {
    setDropDownIds(filteredAliases);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Full control of height
      backgroundColor:
          Colors.transparent, // Transparent background for custom styling
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AnimatedContainer(
              duration: Duration(milliseconds: 500),
              curve: Curves.easeOutExpo,
              height: 350, // Increased height for better spacing
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context)
                      .viewInsets
                      .bottom), // Adjust for keyboard
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with Fade Animation
                        AnimatedOpacity(
                          duration: Duration(milliseconds: 500),
                          opacity: 1.0,
                          child: Text(
                            "Deployment Configuration",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),

                        // Description Text with Fade Effect
                        AnimatedOpacity(
                          duration: Duration(milliseconds: 700),
                          opacity: 1.0,
                          child: Text(
                            "Please configure the details below before proceeding.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Dropdown with Style
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              "Select Account:",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 0),
                              decoration: BoxDecoration(
                                  // color: Colors.black,
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      Border.all(color: Colors.grey, width: 1)),
                              child: DropdownButtonHideUnderline(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: DropdownButton<String>(
                                    value: selectedDropDownValue,
                                    hint: Text(
                                      "Select Broker",
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 16),
                                    ),
                                    dropdownColor: Colors.grey,
                                    elevation: 5,
                                    icon: Icon(Icons.arrow_drop_down,
                                        color: Colors.black, size: 28),
                                    onChanged: (String? newValue) {
                                      handleInputChange(newValue!, "Account");

                                      setModalState(() {
                                        selectedDropDownValue = newValue!;
                                      });
                                    },
                                    items: dropDownItems.map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 16),
                                        ),
                                      );
                                    }).toList(),
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.yellow, // Button color
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5, // Elevation for effect
                          ),
                          onPressed: () async {
                            setState(() {
                              isLoading = true; // Start loading
                              handleDeploy();
                            });

                            // Simulate a network call or processing
                            await Future.delayed(Duration(seconds: 2));

                            setState(() {
                              isLoading =
                                  false; // Stop loading after processing
                            });
                          },
                          child: isLoading
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Deploying...",
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.white),
                                    ),
                                  ],
                                )
                              : Text(
                                  "Confirm",
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.white),
                                ),
                        ),
                      ],
                    ),
                  ),

                  // Close Button in Top Right
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.1),
                        ),
                        child: Icon(Icons.close, color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
