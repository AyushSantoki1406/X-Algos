import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:xalgo/theme/app_colors.dart';
import 'package:xalgo/widgets/drawer_widget.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xalgo/theme/theme_manage.dart';
import 'package:xalgo/secret/secret.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        Uri.parse('${Secret.backendUrl}/getMarketPlaceData'),
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
        Uri.parse('${Secret.backendUrl}/updateSubscribe'),
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
        Uri.parse('${Secret.backendUrl}/addDeployed'),
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
    final themeManager = Provider.of<ThemeProvider>(context);

    return Scaffold(
        key: _scaffoldKey,
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
                  'Market place',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: themeManager.themeMode == ThemeMode.dark
                        ? AppColors.lightPrimary
                        : AppColors.darkPrimary,
                  ),
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
            body: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Colors.amber,
                    ),
                  )
                : ListView.builder(
                    itemCount: strategyData.length,
                    itemBuilder: (context, index) {
                      final strategy = strategyData[index];
                      bool isSubscribed =
                          subscribedStrategies.contains(strategy['_id']);
                      return Container(
                        margin: EdgeInsets.all(0),
                        color: themeManager.themeMode == ThemeMode.dark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                        padding: EdgeInsets.only(left: 16, right: 16),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, top: 0, bottom: 30),
                          child: Container(
                            margin: EdgeInsets.all(0),
                            child: Card(
                              margin: EdgeInsets.all(0),
                              color: themeManager.themeMode == ThemeMode.dark
                                  ? AppColors.bd_black
                                  : AppColors.bd_white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 8.0, right: 8, top: 10, bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header Section
                                    Card(
                                      color: themeManager.themeMode ==
                                              ThemeMode.dark
                                          ? AppColors.bd_black
                                          : AppColors.bd_white,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
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
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: themeManager
                                                                  .themeMode ==
                                                              ThemeMode.dark
                                                          ? AppColors
                                                              .lightPrimary
                                                          : AppColors
                                                              .darkPrimary),
                                                ),
                                                Text(
                                                  'Strategy: ${strategy['strategyType']}',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: themeManager
                                                                  .themeMode ==
                                                              ThemeMode.dark
                                                          ? AppColors
                                                              .lightPrimary
                                                          : AppColors
                                                              .darkPrimary),
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
                                                color: themeManager
                                                            .themeMode ==
                                                        ThemeMode.dark
                                                    ? AppColors.lightPrimary
                                                    : AppColors.darkPrimary),
                                          ),
                                          Text(
                                            strategy['capitalRequirement'],
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: themeManager
                                                            .themeMode ==
                                                        ThemeMode.dark
                                                    ? AppColors.lightPrimary
                                                    : AppColors.darkPrimary),
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
                                            fontSize: 12,
                                            color: themeManager.themeMode ==
                                                    ThemeMode.dark
                                                ? AppColors.lightPrimary
                                                : AppColors.darkPrimary),
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    // Execution Info
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Card(
                                          color: themeManager.themeMode ==
                                                  ThemeMode.dark
                                              ? AppColors.bd_black
                                              : AppColors.bd_white,
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Row(
                                              children: [
                                                Text(
                                                  "✍️  Created By: ${strategy['createdBy']}",
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: themeManager
                                                                  .themeMode ==
                                                              ThemeMode.dark
                                                          ? AppColors
                                                              .lightPrimary
                                                          : AppColors
                                                              .darkPrimary),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Card(
                                          color: themeManager.themeMode ==
                                                  ThemeMode.dark
                                              ? AppColors.bd_black
                                              : AppColors.bd_white,
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Row(
                                              children: [
                                                Text(
                                                  "📅  Created on: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(strategy['dateOfCreation']))}",
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: themeManager
                                                                  .themeMode ==
                                                              ThemeMode.dark
                                                          ? AppColors
                                                              .lightPrimary
                                                          : AppColors
                                                              .darkPrimary),
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
                                                      color: themeManager
                                                                  .themeMode ==
                                                              ThemeMode.dark
                                                          ? AppColors.bd_black
                                                          : AppColors.bd_white,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Row(
                                                          children: [
                                                            Text(
                                                              "👥  Subscriber: ${strategy['subscribeCount']}",
                                                              style: TextStyle(
                                                                  fontSize: 13,
                                                                  color: themeManager
                                                                              .themeMode ==
                                                                          ThemeMode
                                                                              .dark
                                                                      ? AppColors
                                                                          .lightPrimary
                                                                      : AppColors
                                                                          .darkPrimary),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  // Second child with half the width
                                                  Expanded(
                                                    child: Card(
                                                      color: themeManager
                                                                  .themeMode ==
                                                              ThemeMode.dark
                                                          ? AppColors.bd_black
                                                          : AppColors.bd_white,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Row(
                                                          children: [
                                                            Text(
                                                              "🚀  Deployed: ${strategy['deployedCount']}",
                                                              style: TextStyle(
                                                                  fontSize: 13,
                                                                  color: themeManager
                                                                              .themeMode ==
                                                                          ThemeMode
                                                                              .dark
                                                                      ? AppColors
                                                                          .lightPrimary
                                                                      : AppColors
                                                                          .darkPrimary),
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
                                          color: themeManager.themeMode ==
                                                  ThemeMode.dark
                                              ? AppColors.bd_black
                                              : AppColors.bd_white,
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Row(
                                              children: [
                                                Text(
                                                  "🕒  All Days at ${strategy['time']}",
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: themeManager
                                                                  .themeMode ==
                                                              ThemeMode.dark
                                                          ? AppColors
                                                              .lightPrimary
                                                          : AppColors
                                                              .darkPrimary),
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
                                        height:
                                            40, // Define a height for the Row
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: isSubscribed
                                                    ? null
                                                    : () => handleSubscribe(
                                                        strategy['_id']),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: isSubscribed
                                                      ? Colors.grey.shade700
                                                      : themeManager
                                                                  .themeMode ==
                                                              ThemeMode.dark
                                                          ? AppColors
                                                              .lightPrimary
                                                          : AppColors
                                                              .darkPrimary, // Background color based on theme

                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12.0), // Smooth rounded corners
                                                    side: BorderSide(
                                                      color: isSubscribed
                                                          ? Colors.grey.shade600
                                                          : themeManager
                                                                      .themeMode ==
                                                                  ThemeMode.dark
                                                              ? AppColors
                                                                  .lightPrimary
                                                              : AppColors
                                                                  .darkPrimary, // Border color
                                                      width: 2.0,
                                                    ),
                                                  ),

                                                  elevation: isSubscribed
                                                      ? 0
                                                      : 5, // Adds depth when enabled
                                                  shadowColor: Colors.black
                                                      .withOpacity(
                                                          0.3), // Subtle shadow
                                                  padding: EdgeInsets.symmetric(
                                                      vertical:
                                                          5), // Better spacing
                                                ),
                                                child: Text(
                                                  isSubscribed
                                                      ? "Subscribed"
                                                      : "Subscribe",
                                                  style: TextStyle(
                                                    fontSize:
                                                        14, // Slightly larger text
                                                    fontWeight: FontWeight
                                                        .bold, // Makes it stand out
                                                    letterSpacing:
                                                        0.8, // Improves readability
                                                    color: isSubscribed
                                                        ? Colors.grey.shade400
                                                        : themeManager
                                                                    .themeMode ==
                                                                ThemeMode.dark
                                                            ? AppColors
                                                                .darkPrimary
                                                            : AppColors
                                                                .lightPrimary, // Text color
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: isSubscribed
                                                    ? () => handleOpen(
                                                        strategy['_id'])
                                                    : null,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: isSubscribed
                                                      ? Color.fromARGB(
                                                          255,
                                                          25,
                                                          25,
                                                          25) // Dark background when enabled
                                                      : Colors.grey
                                                          .shade600, // Lighter gray when disabled

                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12.0), // Smooth rounded corners
                                                    side: isSubscribed
                                                        ? BorderSide
                                                            .none // No border if subscribed
                                                        : BorderSide(
                                                            color: themeManager.themeMode ==
                                                                    ThemeMode
                                                                        .dark
                                                                ? AppColors
                                                                    .lightPrimary
                                                                : AppColors
                                                                    .darkPrimary, // Dynamic border color
                                                            width: 2.0,
                                                          ),
                                                  ),

                                                  elevation: isSubscribed
                                                      ? 4
                                                      : 0, // Subtle shadow when enabled
                                                  shadowColor: Colors.black
                                                      .withOpacity(0.3),
                                                  padding: EdgeInsets.symmetric(
                                                      vertical:
                                                          5), // Spacing for better UX
                                                ),
                                                child: Text(
                                                  "Deploy",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.7,
                                                    color: isSubscribed
                                                        ? AppColors.lightPrimary
                                                        : themeManager
                                                                    .themeMode ==
                                                                ThemeMode.dark
                                                            ? AppColors
                                                                .lightPrimary
                                                            : AppColors
                                                                .darkPrimary, // Text color based on theme
                                                  ),
                                                ),
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
        ));
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
