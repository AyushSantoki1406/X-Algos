import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:xalgo/widgets/drawer_widget.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  late Map<String, dynamic> userSchema;
  late Map<String, dynamic> clientData;
  late Map<String, dynamic> accountAliases;
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  void onBrokerChange(String? newValue) {
    setState(() {
      selectBroker = newValue!;
    });
  }

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

  Future<void> fetchData() async {
    String? email = await getEmail();

    setState(() {
      tableLoader = true;
    });
    try {
      // Fetch user data
      var response = await http.post(
        Uri.parse('https://oyster-app-4y3eb.ondigitalocean.app/userinfo'),
        body: json.encode({'Email': email}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          userSchema = json.decode(response.body); // Decoding response data
          tableLoader = false;
        });
      } else {
        // Handle unsuccessful response
        throw Exception('Failed to load user data');
      }

      // Simulate database schema fetch
      var dbSchemaResponse = await http.post(
        Uri.parse('https://oyster-app-4y3eb.ondigitalocean.app/dbSchema'),
        body: json.encode({'Email': email}),
        headers: {'Content-Type': 'application/json'},
      );

      if (dbSchemaResponse.statusCode == 200) {
        userSchema = json.decode(dbSchemaResponse.body);
        accountAliases = userSchema['AccountAliases'] ?? {};
      } else {
        // Handle unsuccessful response
        throw Exception('Failed to load DB schema');
      }
    } catch (error) {
      // Handle error
      print('Error: $error');
    } finally {
      setState(() {
        tableLoader = false;
      });
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
    setState(() {
      alertMessage2 = message;
    });

    Future.delayed(Duration(milliseconds: duration), () {
      setState(() {
        alertMessage2 = '';
      });
    });
  }

  void checkAccountAlias(String accountName) {
    final aliases = userSchema['AccountAliases'] ?? {};

    setState(() {
      existingAlias = aliases.containsValue(accountName);
    });
  }

  void addBrokerBtn() async {
    setState(() {
      loading = true;
    });

    bool userExist = false;

    if (userSchema['AngelBrokerData'] != null) {
      for (var item in userSchema['AngelBrokerData']) {
        if (item['AngelId'] == id) {
          userExist = true;
        }
      }
    }

    if (userSchema['DeltaBrokerSchema'] != null) {
      for (var item in userSchema['DeltaBrokerSchema']) {
        if (item['deltaApiKey'] == deltaKey) {
          userExist = true;
        }
      }
    }

    if (userSchema['AccountAliases'] != null) {
      existingAlias = userSchema['AccountAliases']
          .values
          .contains(accountName.toLowerCase());
    }

    if (existingAlias) {
      showAlertWithTimeout("Account Name is not available", 2000);
      setState(() {
        loading = false;
      });
    } else if (userExist) {
      showAlertWithTimeout("Broker already added", 2000);
      setState(() {
        loading = false;
      });
    } else {
      try {
        final url = 'http://localhost:5000/addbroker';
        final response = await http.post(
          Uri.parse(url),
          body: json.encode({
            'First': true,
            'id': id,
            'pass': pass,
            'email': email,
            'secretKey': secretKey,
            'userSchema': userSchema,
            'ApiKey': apikey,
            'accountName': accountName,
          }),
        );

        if (response.statusCode == 200) {
          showAlertWithTimeout2("Successfully added", 3000);
          // Handle the successful response
        } else {
          showAlertWithTimeout("Invalid id or password", 5000);
        }
      } catch (e) {
        showAlertWithTimeout("Error occurred: $e", 5000);
      }
      setState(() {
        loading = false;
      });
    }
  }

  // Method to conditionally show different forms
  Widget buildBrokerForm() {
    switch (selectBroker) {
      case '1': // AngelOne
        return Column(
          children: [
            TextField(
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                labelText: "Account Name",
                labelStyle: TextStyle(
                  fontSize: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                ),
                filled: true,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                fillColor: Color(0xFF1A1A1A),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: Color(0xFF3D3E57), width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: Color(0xFF3D3E57), width: 0.5),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                labelText: "Client ID",
                labelStyle: TextStyle(
                  fontSize: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                ),
                filled: true,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                fillColor: Color(0xFF1A1A1A),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: Color(0xFF3D3E57), width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: Color(0xFF3D3E57), width: 0.5),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                labelText: "Enter Pin",
                labelStyle: TextStyle(
                  fontSize: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                ),
                filled: true,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                fillColor: Color(0xFF1A1A1A),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: Color(0xFF3D3E57), width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: Color(0xFF3D3E57), width: 0.5),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                labelText: "Totp Key",
                labelStyle: TextStyle(
                  fontSize: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                ),
                filled: true,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                fillColor: Color(0xFF1A1A1A),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: Color(0xFF3D3E57), width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: Color(0xFF3D3E57), width: 0.5),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                labelText: "Api Key",
                labelStyle: TextStyle(
                  fontSize: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                ),
                filled: true,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                fillColor: Color(0xFF1A1A1A),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: Color(0xFF3D3E57), width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: Color(0xFF3D3E57), width: 0.5),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
            ),
            SizedBox(height: 20),
          ],
        );
      case '2': // Delta
        return Column(
          children: [
            TextField(
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                labelText: "Account Name",
                labelStyle: TextStyle(
                  fontSize: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                ),
                filled: true,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                fillColor: Color(0xFF1A1A1A),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: Color(0xFF3D3E57), width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: Color(0xFF3D3E57), width: 0.5),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                labelText: "API Key",
                labelStyle: TextStyle(
                  fontSize: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                ),
                filled: true,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                fillColor: Color(0xFF1A1A1A),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: Color(0xFF3D3E57), width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: Color(0xFF3D3E57), width: 0.5),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                labelText: "API Secret",
                labelStyle: TextStyle(
                  fontSize: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                ),
                filled: true,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                fillColor: Color(0xFF1A1A1A),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: Color(0xFF3D3E57), width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.2),
                  borderSide: BorderSide(color: Color(0xFF3D3E57), width: 0.5),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              ),
            ),
            SizedBox(height: 20),
          ],
        );
      case '3': // Upstox
        return Column(
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Upstox API Key'),
              onChanged: (value) {
                setState(() {
                  apikey = value;
                });
              },
            ),
            // Add more fields related to Upstox if needed
          ],
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Manage Broker',
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
      body: Container(
        padding: const EdgeInsets.all(16),
        color: Color(0xFF000000),
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      margin: EdgeInsets.only(left: 8, right: 8, bottom: 8),
                      child: DropdownButton<String>(
                        value: selectBroker,
                        onChanged: onBrokerChange,
                        isExpanded: true,
                        style: TextStyle(color: Colors.grey),
                        items: [
                          DropdownMenuItem(value: "1", child: Text("AngelOne")),
                          DropdownMenuItem(value: "2", child: Text("Delta")),
                          DropdownMenuItem(value: "3", child: Text("Upstox")),
                        ],
                      ),
                    ),
                  ),
                  // Render the form based on the selected broker
                  Padding(padding: EdgeInsets.all(8), child: buildBrokerForm()),
                  Container(
                    margin: EdgeInsets.only(left: 8, right: 8, bottom: 8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFBD535),
                        minimumSize:
                            Size(double.infinity, 50), // Full width button
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        side: BorderSide.none, // Remove border
                      ),
                      onPressed: existingAlias || angelIdExist
                          ? null
                          : addBrokerBtn, // Disable button if conditions are met
                      child: Text(
                        'Add Broker',
                        style: TextStyle(color: Colors.black), // Text color
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
