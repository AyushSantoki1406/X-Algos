import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:xalgo/secret/secret.dart';
import 'package:xalgo/theme/app_colors.dart';
import 'package:xalgo/widgets/drawer_widget.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:xalgo/theme/theme_manage.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ManageBroker extends StatefulWidget {
  const ManageBroker({super.key});

  @override
  State<ManageBroker> createState() => _ManageBrokerState();
}

class _ManageBrokerState extends State<ManageBroker> {
  String email = '';
  String accountName = '';
  String pass = '';
  String id = '';
  String secretKey = '';
  String deltaSecret = '';
  String deltaKey = '';
  String apikey = '';
  String selectBroker = '1';
  bool angelIdExist = false;
  bool deltaApiKeyExist = false;
  bool tableLoader = false;
  bool existingAlias = false;
  bool isLoggedIn = false;
  bool loading = false;
  String alertMessage = '';
  String alertMessage2 = '';
  late Map<String, dynamic> userSchema = {};
  List<Map<String, dynamic>> clientData = []; // Declare clientData as a list
  late List<dynamic> angelBrokerData = [];
  late List<dynamic> deltaBrokerSchema = [];
  late Map<String, dynamic> accountAliases;
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  List<Map<String, dynamic>> matchedClients = [];
  List<dynamic> allClientsData = []; // Create a list to store all users

  int? selectedIndex;

  TextEditingController _accountName = TextEditingController();
  TextEditingController _clientId = TextEditingController();
  TextEditingController _clientIdPIN = TextEditingController();
  TextEditingController _clientAPIKey = TextEditingController();
  TextEditingController _clientTotpKey = TextEditingController();
  TextEditingController _clientApiSecret = TextEditingController();

  void onBrokerChange(String? newValue) {
    setState(() {
      selectBroker = newValue!;
    });
  }

  Future<String?> getEmail() async {
    try {
      String? userEmail = await secureStorage.read(key: 'Email');
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

  void checkAccountAlias(String accountName) {
    final aliases = userSchema['AccountAliases'] ?? {};

    setState(() {
      existingAlias = aliases.containsValue(accountName);
    });
  }

  Future<void> fetchData() async {
    String? email = await getEmail();

    setState(() {
      tableLoader = true;
    });

    try {
      //client data is here userinfo route show client id and all things for <<<<<<<<<< ANGLE ONE >>>>>>>>>>>>>>
      var response = await http.post(
        Uri.parse('${Secret.backendUrl}/userinfo'),
        body: json.encode({'Email': email}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            List<dynamic> usersList = json.decode(response.body);
            List<Map<String, dynamic>> allClientsData = [];

            for (var user in usersList) {
              var userData = user['userData'];
              print("userdata is here >>>>>>>>>>>>>>>>>>>>>>>>$userData");

              if (userData != null && userData['data'] != null) {
                allClientsData.add(Map<String, dynamic>.from(userData['data']));
              }

              print("AngleOne data is fetched from db");
            }

            clientData = allClientsData;
            tableLoader = false;
          });
        }
      } else {
        throw Exception('Failed to load user data');
      }

      //client data is here userinfo route show client id and all things for <<<<<<<<<< ANGLE ONE AND DELTA >>>>>>>>>>>>>>
      var dbSchemaResponse = await http.post(
        Uri.parse('${Secret.backendUrl}/dbSchema'),
        body: json.encode({'Email': email}),
        headers: {'Content-Type': 'application/json'},
      );

      var responseBody = json.decode(dbSchemaResponse.body);

      if (dbSchemaResponse.statusCode == 200) {
        if (mounted) {
          setState(() {
            if (responseBody is Map<String, dynamic>) {
              userSchema = responseBody;
              angelBrokerData = responseBody['AngelBrokerData'] ?? [];
              deltaBrokerSchema = responseBody['DeltaBrokerSchema'] ?? [];
              print(">>>>>>>>>>>>>bbbbbbbbbbbbbbbb>>>");
              print(clientData);
              print(">>>>>>>>>>>>>bbbbbbbbbbbbbbbb>>>");

              for (var client in clientData) {
                String clientId = client['clientcode'];

                var matchedBroker = angelBrokerData.firstWhere(
                  (broker) => broker['AngelId'] == clientId,
                  orElse: () => null,
                );

                String accountAlice =
                    userSchema['AccountAliases'][clientId] ?? "No Alias Found";

                print("Client ID: $clientId, Account Alias: $accountAlice");

                if (matchedBroker != null) {
                  matchedClients.add({
                    "clientid": clientId,
                    "account_alice": accountAlice,
                    "name": client['name'],
                    "date": matchedBroker['Date'],
                    "broker_name": "AngelOne"
                  });
                }
                print("😶$matchedClients");
              }
            } else {
              print(
                  'Unexpected response format: Expected a Map but got ${responseBody.runtimeType}');
            }
          });
        }
      }
    } catch (error) {
      // Handle error
      print('Error: $error');
    } finally {
      if (mounted) {
        setState(() {
          tableLoader = false;
        });
      }
    }
  }

  void showAlertWithTimeout(String message, int duration) {
    setState(() {
      alertMessage = message;
    });

    Future.delayed(Duration(milliseconds: duration), () {
      setState(() {
        alertMessage = '';
      });
    });
  }

  void showAlertWithTimeout2(String message, int duration) {
    if (!mounted) return; // ✅ Ensure widget is still in the tree

    setState(() {
      alertMessage2 = message;
    });

    Future.delayed(Duration(milliseconds: duration), () {
      if (mounted) {
        setState(() {
          alertMessage2 = '';
        });
      }
    });
  }

  void addBrokerBtn() async {
    setState(() {
      loading = true;
    });

    bool userExist = false;

    //only fetch user, angle accounts chek its there or not
    if (userSchema['AngelBrokerData'] != null) {
      for (var item in userSchema['AngelBrokerData']) {
        if (item['AngelId'] == id) {
          userExist = true;
          print("😟");
        }
      }
    }

    print(userSchema);

    //only fetch user, delta accounts chek its there or not
    if (userSchema['DeltaBrokerSchema'] != null) {
      for (var item in userSchema['DeltaBrokerSchema']) {
        if (item['deltaApiKey'] == deltaKey) {
          userExist = true;
          print("🥹");
        }
      }
    }

    //change case to uppercase
    if (userSchema['AccountAliases'] != null) {
      existingAlias = userSchema['AccountAliases']
          .values
          .contains(accountName.toLowerCase());
    }

    if (existingAlias) {
      showAlertWithTimeout("Account Name is not available", 2000);
      setState(() {
        loading = false;
        print("😂");
      });
    } else if (userExist) {
      showAlertWithTimeout("Broker already added", 2000);
      setState(() {
        loading = false;
        print("😁");
      });
    } else {
      print("😊 Emojis here 😊");
      try {
        String? email = await getEmail();

        final response = await http.post(
          Uri.parse('${Secret.backendUrl}/addbroker'),
          body: json.encode({
            'First': true,
            'id': _clientId.text,
            'pass': _clientIdPIN.text,
            'email': email,
            'secretKey': _clientTotpKey.text,
            'userSchema': userSchema,
            'ApiKey': _clientAPIKey.text,
            'accountName': _accountName.text,
          }),
          headers: {'Content-Type': 'application/json'},
        );

        print("🚀 Emojis here 🚀");

        if (response.statusCode == 200) {
          showAlertWithTimeout2("Successfully added", 3000);
          // Handle the successful response

          print("done");

          final response = await http.post(
            Uri.parse("${Secret.backendUrl}/dbSchema"),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({"Email": email}),
          );

          final data = response.body; // No need to jsonEncode(response.body)

          await secureStorage.write(key: 'userSchema', value: data);

          String? userSchemaString =
              await secureStorage.read(key: 'userSchema');
          if (userSchemaString != null) {
            // Decode the JSON string into a Map
            Map<String, dynamic> userSchema = jsonDecode(userSchemaString);

            print("???????????");
            print(userSchema['BrokerCount']);

            // Ensure 'BrokerCount' is a String before parsing to int
            String brokerCountString = userSchema['BrokerCount'].toString();
            print("brokerCountString ${brokerCountString}");
            int brokerCount = int.tryParse(brokerCountString) ?? 0;
            print("brokerCountString>>>>> ${brokerCount}");

            if (brokerCount > 0) {
              print("brokerCountString>>>>> 1");
              await secureStorage.write(
                  key: 'BrokerCount', value: true.toString());
            } else {
              print("brokerCountString>>>>> 2");
              await secureStorage.write(
                  key: 'BrokerCount', value: false.toString());
            }

            String? brokerCount2 = await secureStorage.read(key: 'BrokerCount');
            print('BrokerCount is: $brokerCount2');
          } else {
            print('No user schema found');
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    ManageBroker()), // Replace with your screen widget
          );
        } else {
          showAlertWithTimeout("Invalid id or password", 5000);
          print("not done");
        }
      } catch (e) {
        print("not>>> done");
        showAlertWithTimeout("Error occurred: $e", 5000);
      }
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> deleteBroker(int index, String clientId) async {
    String? email = await getEmail();

    final response = await http.post(
      Uri.parse('${Secret.backendUrl}/removeClient'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "Email": email,
        "index": index,
        "clientId": clientId,
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ManageBroker()), // Replace with your screen widget
      );
      print("Client removed successfully");
    } else {
      print("Failed to remove client: ${response.body}");
    }
  }

  // Method to conditionally show different forms
  Widget buildBrokerForm() {
    final themeManager = Provider.of<ThemeProvider>(context);

    switch (selectBroker) {
      case '1': // AngelOne
        return Column(
          children: [
            TextField(
              controller: _accountName,
              decoration: InputDecoration(
                labelText: "Account Name",
                labelStyle: TextStyle(
                    fontSize: 13,
                    color: themeManager.isDarkMode == ThemeMode.dark
                        ? AppColors.lightPrimary
                        : AppColors.darkPrimary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                ),
                filled: true,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                fillColor: Colors.transparent,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(
                      color: themeManager.isDarkMode == ThemeMode.dark
                          ? AppColors.lightPrimary
                          : AppColors.darkPrimary,
                      width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: AppColors.yellow, width: 1),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _clientId,
              decoration: InputDecoration(
                labelText: "Client ID",
                labelStyle: TextStyle(
                    fontSize: 13,
                    color: themeManager.isDarkMode == ThemeMode.dark
                        ? AppColors.lightPrimary
                        : AppColors.darkPrimary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                ),
                filled: true,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                fillColor: Colors.transparent,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(
                      color: themeManager.isDarkMode == ThemeMode.dark
                          ? AppColors.lightPrimary
                          : AppColors.darkPrimary,
                      width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: AppColors.yellow, width: 0.5),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
              onChanged: (value) {
                setState(() {
                  id = value; // Updates the variable dynamically
                });
              },
            ),
            SizedBox(height: 10),
            TextField(
              controller: _clientIdPIN,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                labelText: "Enter Pin",
                labelStyle: TextStyle(
                    fontSize: 13,
                    color: themeManager.isDarkMode == ThemeMode.dark
                        ? AppColors.lightPrimary
                        : AppColors.darkPrimary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                ),
                filled: true,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                fillColor: Colors.transparent,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(
                      color: themeManager.isDarkMode == ThemeMode.dark
                          ? AppColors.lightPrimary
                          : AppColors.darkPrimary,
                      width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: AppColors.yellow, width: 0.5),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _clientTotpKey,
              decoration: InputDecoration(
                labelText: "Totp Key",
                labelStyle: TextStyle(
                    fontSize: 13,
                    color: themeManager.isDarkMode == ThemeMode.dark
                        ? AppColors.lightPrimary
                        : AppColors.darkPrimary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                ),
                filled: true,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                fillColor: Colors.transparent,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(
                      color: themeManager.isDarkMode == ThemeMode.dark
                          ? AppColors.lightPrimary
                          : AppColors.darkPrimary,
                      width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: AppColors.yellow, width: 0.5),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _clientAPIKey,
              decoration: InputDecoration(
                labelText: "Api Key",
                labelStyle: TextStyle(
                    fontSize: 13,
                    color: themeManager.isDarkMode == ThemeMode.dark
                        ? AppColors.lightPrimary
                        : AppColors.darkPrimary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                ),
                filled: true,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                fillColor: Colors.transparent,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(
                      color: themeManager.isDarkMode == ThemeMode.dark
                          ? AppColors.lightPrimary
                          : AppColors.darkPrimary,
                      width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: AppColors.yellow, width: 0.5),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
            ),
            SizedBox(height: 10),
          ],
        );
      case '2': // Delta
        return Column(
          children: [
            TextField(
              controller: _accountName,
              decoration: InputDecoration(
                labelText: "Account Name",
                labelStyle: TextStyle(
                    fontSize: 13,
                    color: themeManager.isDarkMode == ThemeMode.dark
                        ? AppColors.lightPrimary
                        : AppColors.darkPrimary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                ),
                filled: true,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                fillColor: Colors.transparent,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(
                      color: themeManager.isDarkMode == ThemeMode.dark
                          ? AppColors.lightPrimary
                          : AppColors.darkPrimary,
                      width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: AppColors.yellow, width: 0.5),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _clientAPIKey,
              decoration: InputDecoration(
                labelText: "API Key",
                labelStyle: TextStyle(
                    fontSize: 13,
                    color: themeManager.isDarkMode == ThemeMode.dark
                        ? AppColors.lightPrimary
                        : AppColors.darkPrimary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                ),
                filled: true,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                fillColor: Colors.transparent,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(
                      color: themeManager.isDarkMode == ThemeMode.dark
                          ? AppColors.lightPrimary
                          : AppColors.darkPrimary,
                      width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: AppColors.yellow, width: 0.5),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _clientApiSecret,
              decoration: InputDecoration(
                labelText: "API Secret",
                labelStyle: TextStyle(
                    fontSize: 13,
                    color: themeManager.isDarkMode == ThemeMode.dark
                        ? AppColors.lightPrimary
                        : AppColors.darkPrimary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                ),
                filled: true,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                fillColor: Colors.transparent,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(
                      color: themeManager.isDarkMode == ThemeMode.dark
                          ? AppColors.lightPrimary
                          : AppColors.darkPrimary,
                      width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: AppColors.yellow, width: 0.5),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
            ),
            SizedBox(height: 10),
          ],
        );
      case '3': // Upstox
        return Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: "Upstox API",
                labelStyle: TextStyle(
                    fontSize: 13,
                    color: themeManager.isDarkMode == ThemeMode.dark
                        ? AppColors.lightPrimary
                        : AppColors.darkPrimary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                ),
                filled: true,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                fillColor: Colors.transparent,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(
                      color: themeManager.isDarkMode == ThemeMode.dark
                          ? AppColors.lightPrimary
                          : AppColors.darkPrimary,
                      width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: AppColors.yellow, width: 0.5),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
            ),
            SizedBox(height: 10)
            // Add more fields related to Upstox if needed
          ],
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    final themeManager = Provider.of<ThemeProvider>(context);

    String? selectedValue;
    String? selectedAccount;

    return Scaffold(
      key: _scaffoldKey, // Assign the key to Scaffold
      // endDrawer: AppDrawer(),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {},
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              pinned: true,
              backgroundColor: themeManager.isDarkMode == ThemeMode.dark
                  ? AppColors.darkPrimary
                  : AppColors.lightPrimary,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              title: Text(
                'Manage Broker',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: themeManager.isDarkMode == ThemeMode.dark
                        ? AppColors.lightPrimary
                        : AppColors.darkPrimary),
              ),
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: themeManager.isDarkMode == ThemeMode.dark
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
                    icon: Icon(
                      Icons.menu,
                      color: themeManager.isDarkMode
                          ? AppColors.lightPrimary
                          : AppColors.darkPrimary,
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyAccountPage(),
                            settings: RouteSettings(),
                            fullscreenDialog: false,
                          ));
                    },
                  ),
                ),
              ],
            ),
          ],
          body: Container(
            color: themeManager.isDarkMode == ThemeMode.dark
                ? AppColors.darkPrimary
                : AppColors.lightPrimary,
            padding: const EdgeInsets.all(4),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Card(
                color: themeManager.isDarkMode == ThemeMode.dark
                    ? AppColors.bd_black
                    : AppColors.bd_white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          margin: EdgeInsets.only(left: 20, right: 20),
                          child: DropdownButton<String>(
                            dropdownColor:
                                themeManager.isDarkMode == ThemeMode.dark
                                    ? AppColors.darkBackground
                                    : AppColors.lightPrimary,
                            value: selectBroker,
                            onChanged: onBrokerChange,
                            isExpanded: true,
                            style: TextStyle(color: Colors.grey),
                            iconEnabledColor: themeManager.isDarkMode ==
                                    ThemeMode.dark
                                ? AppColors
                                    .lightPrimary // Icon color in dark mode
                                : AppColors
                                    .darkPrimary, // Icon color in light mode
                            underline: Container(
                              height: 2,
                              color: themeManager.isDarkMode == ThemeMode.dark
                                  ? AppColors
                                      .lightPrimary // Underline color in dark mode
                                  : AppColors
                                      .darkPrimary, // Underline color in light mode
                            ),
                            items: [
                              DropdownMenuItem(
                                value: "1",
                                child: Text(
                                  "AngelOne",
                                  style: TextStyle(
                                    color: themeManager.isDarkMode ==
                                            ThemeMode.dark
                                        ? AppColors.lightPrimary
                                        : AppColors.darkPrimary,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: "2",
                                child: Text(
                                  "Delta",
                                  style: TextStyle(
                                    color: themeManager.isDarkMode ==
                                            ThemeMode.dark
                                        ? AppColors.lightPrimary
                                        : AppColors.darkPrimary,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: "3",
                                child: Text(
                                  "Upstox",
                                  style: TextStyle(
                                    color: themeManager.isDarkMode ==
                                            ThemeMode.dark
                                        ? AppColors.lightPrimary
                                        : AppColors.darkPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Render the form based on the selected broker
                      Padding(
                          padding: EdgeInsets.all(8), child: buildBrokerForm()),
                      Container(
                        margin: EdgeInsets.only(left: 8, right: 8),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFBD535),
                            minimumSize:
                                Size(double.infinity, 50), // Full-width button
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            side: BorderSide.none, // Remove border
                          ),
                          onPressed: existingAlias || angelIdExist
                              ? null
                              : addBrokerBtn,
                          child: Text(
                            'Add Broker',
                            style: TextStyle(
                              color: themeManager.isDarkMode == ThemeMode.dark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary,
                            ), // Text color
                          ),
                        ),
                      ),

                      Container(
                        margin: EdgeInsets.only(top: 10),
                        padding: EdgeInsets.all(0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(bottom: 0),
                            ),
                            isLoggedIn
                                ? Container(
                                    // margin: const EdgeInsets.only(
                                    //     bottom: 10),
                                    height: 37,
                                    width:
                                        MediaQuery.of(context).size.width * 0.2,
                                    child: Container(
                                      height: 37,
                                      width: MediaQuery.of(context).size.width *
                                          0.2,
                                      child: Center(
                                        child: LoadingAnimationWidget.waveDots(
                                          color: themeManager.isDarkMode ==
                                                  ThemeMode.dark
                                              ? AppColors.lightPrimary
                                              : AppColors.darkPrimary,
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                  )
                                : SingleChildScrollView(
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: matchedClients.length ?? 0,
                                      itemBuilder: (context, index) {
                                        bool isSelected =
                                            selectedIndex == index;
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedIndex =
                                                  isSelected ? null : index;
                                            });
                                          },
                                          child: Container(
                                            margin: EdgeInsets.symmetric(
                                                vertical: 5),
                                            padding: EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isSelected
                                                    ? (themeManager
                                                                .isDarkMode ==
                                                            ThemeMode.dark
                                                        ? AppColors.lightPrimary
                                                        : AppColors.darkPrimary)
                                                    : Colors.grey,
                                                width: 2,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    // Text(
                                                    //   "Accounts",
                                                    //   style: TextStyle(
                                                    //     fontSize: 16,
                                                    //     fontWeight: FontWeight.bold,
                                                    //     color: themeManager
                                                    //                 .isDarkMode ==
                                                    //             ThemeMode.dark
                                                    //         ? AppColors
                                                    //             .lightPrimary // Dark mode
                                                    //         : AppColors
                                                    //             .darkPrimary, // Light mode
                                                    //   ),
                                                    // ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 0.0),
                                                      child: Text(
                                                        "Account Name: ${matchedClients[index]['account_alice']}",
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: themeManager
                                                                      .isDarkMode ==
                                                                  ThemeMode.dark
                                                              ? AppColors
                                                                  .lightPrimary // Dark mode
                                                              : AppColors
                                                                  .darkPrimary, // Light mode
                                                        ),
                                                      ),
                                                    ),
                                                    Spacer(),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 8.0),
                                                      child: Icon(
                                                        isSelected
                                                            ? Icons
                                                                .arrow_drop_up
                                                            : Icons
                                                                .arrow_drop_down,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                // Dropdown list inside the same yellow border
                                                AnimatedSize(
                                                  duration: Duration(
                                                      milliseconds: 300),
                                                  child: isSelected
                                                      ? Column(
                                                          children: [
                                                            Divider(
                                                                color: Colors
                                                                    .grey), // Separator line
                                                            _buildRow(
                                                                "Broker Name",
                                                                '${matchedClients[index]['broker_name']}'),
                                                            _buildRow(
                                                                "Account Alice",
                                                                '${matchedClients[index]['account_alice'].length > 10 ? matchedClients[index]['account_alice'].substring(0, 10) + '..' : matchedClients[index]['account_alice']}'),
                                                            _buildRow("Name",
                                                                '${matchedClients[index]['name'].length > 10 ? matchedClients[index]['name'].substring(0, 10) + '..' : matchedClients[index]['name']}'),
                                                            _buildRow(
                                                                "Client ID",
                                                                '${matchedClients[index]['clientid']}'),
                                                            _buildRow("Date",
                                                                '${matchedClients[index]['date']}'),
                                                            SizedBox(
                                                                height: 10),
                                                            Container(
                                                              width: double
                                                                  .infinity,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color:
                                                                    Colors.red,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                              ),
                                                              child: IconButton(
                                                                icon: Icon(
                                                                    Icons
                                                                        .delete,
                                                                    color: Colors
                                                                        .white),
                                                                onPressed: () {
                                                                  deleteBroker(
                                                                      index,
                                                                      matchedClients[
                                                                              index]
                                                                          [
                                                                          'clientid']);
                                                                },
                                                              ),
                                                            ),
                                                          ],
                                                        )
                                                      : SizedBox.shrink(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      drawer: AppDrawer(), // Optional: left drawer
      endDrawer: AppDrawer(),
    );
  }

  Widget _buildRow(String title, String value) {
    final themeManager = Provider.of<ThemeProvider>(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  color: themeManager.isDarkMode == ThemeMode.dark
                      ? AppColors.lightPrimary
                      : AppColors.darkPrimary),
            ),
            Text(
              value,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 17,
                  color: themeManager.isDarkMode == ThemeMode.dark
                      ? AppColors.lightPrimary
                      : AppColors.darkPrimary),
            ),
          ],
        ),
        Divider(thickness: 1, color: Colors.grey),
        SizedBox(height: 5),
      ],
    );
  }
}
