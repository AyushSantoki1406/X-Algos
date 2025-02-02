import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:xalgo/widgets/drawer_widget.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shimmer/shimmer.dart';

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
        Uri.parse('https://oyster-app-4y3eb.ondigitalocean.app/userinfo'),
        body: json.encode({'Email': email}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          List<dynamic> usersList = json.decode(response.body);
          List<Map<String, dynamic>> allClientsData =
              []; // Store all user data as a list

          for (var user in usersList) {
            var userData = user['userData'];
            print("userdata is here >>>>>>>>>>>>>>>>>>>>>>>>$userData");

            if (userData != null && userData['data'] != null) {
              allClientsData.add(Map<String, dynamic>.from(
                  userData['data'])); // Ensure it's a map
            }

            print("AngleOne data is fetched from db");
          }

          clientData = allClientsData; // Assign list to clientData
          tableLoader = false;
        });
      } else {
        throw Exception('Failed to load user data');
      }

      //client data is here userinfo route show client id and all things for <<<<<<<<<< ANGLE ONE AND DELTA >>>>>>>>>>>>>>
      var dbSchemaResponse = await http.post(
        Uri.parse('https://oyster-app-4y3eb.ondigitalocean.app/dbSchema'),
        body: json.encode({'Email': email}),
        headers: {'Content-Type': 'application/json'},
      );

      var responseBody = json.decode(dbSchemaResponse.body);

      if (dbSchemaResponse.statusCode == 200) {
        var responseBody = json.decode(dbSchemaResponse.body);

        // Ensure responseBody is a Map<String, dynamic>
        if (responseBody is Map<String, dynamic>) {
          setState(() {
            userSchema = responseBody;
            angelBrokerData = responseBody['AngelBrokerData'] ?? [];
            deltaBrokerSchema = responseBody['DeltaBrokerSchema'] ?? [];
            print(">>>>>>>>>>>>>bbbbbbbbbbbbbbbb>>>>>>>");
            print(clientData);
            print(">>>>>>>>>>>>>bbbbbbbbbbbbbbbb>>>>>>>");

            for (var client in clientData) {
              String clientId = client['clientcode'];

              // Find matching broker
              var matchedBroker = angelBrokerData.firstWhere(
                (broker) => broker['AngelId'] == clientId,
                orElse: () => null,
              );

              // Get account alias
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
          });
        } else {
          print(
              'Unexpected response format: Expected a Map but got ${responseBody.runtimeType}');
        }
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
    if (!mounted) return; // ✅ Ensure widget is still in the tree

    setState(() {
      alertMessage2 = message;
    });

    Future.delayed(Duration(milliseconds: duration), () {
      if (mounted) {
        // ✅ Check again before updating UI
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
          Uri.parse('https://oyster-app-4y3eb.ondigitalocean.app/addbroker'),
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
      Uri.parse('https://oyster-app-4y3eb.ondigitalocean.app/removeClient'),
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
            SizedBox(height: 10),
            TextField(
              controller: _clientId,
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
            SizedBox(height: 10),
            TextField(
              controller: _clientTotpKey,
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
            SizedBox(height: 10),
            TextField(
              controller: _clientAPIKey,
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
            SizedBox(height: 10),
            TextField(
              controller: _clientAPIKey,
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
            SizedBox(height: 10),
            TextField(
              controller: _clientApiSecret,
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
            SizedBox(height: 10),
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
    List<bool> switchStates = List.generate(matchedClients.length,
        (index) => true); // Initialize the switch state for each item

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
      drawer: AppDrawer(),
      endDrawer: AppDrawer(),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {},
        child: Container(
          padding: const EdgeInsets.all(4),
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 8),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: Colors.transparent,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        margin: EdgeInsets.only(left: 20, right: 20),
                        child: DropdownButton<String>(
                          value: selectBroker,
                          onChanged: onBrokerChange,
                          isExpanded: true,
                          style: TextStyle(color: Colors.grey),
                          items: [
                            DropdownMenuItem(
                                value: "1", child: Text("AngelOne")),
                            DropdownMenuItem(value: "2", child: Text("Delta")),
                            DropdownMenuItem(value: "3", child: Text("Upstox")),
                          ],
                        ),
                      ),
                    ),
                    // Render the form based on the selected broker
                    Padding(
                        padding: EdgeInsets.all(8), child: buildBrokerForm()),
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
                        onPressed:
                            existingAlias || angelIdExist ? null : addBrokerBtn,
                        child: Text(
                          'Add Broker',
                          style: TextStyle(color: Colors.black), // Text color
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 16),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).cardColor,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Container(
                            child: ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: matchedClients.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10.0),
                              child: Card(
                                color: switchStates[index]
                                    ? Colors.transparent
                                    : Colors
                                        .blue, // Change card color based on switch state
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Row 1: Broker Name & Switch
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${matchedClients[index]['broker_name']}',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 20),
                                          ),
                                          Transform.scale(
                                            scale: 0.8, // Reduce switch size
                                            child: Switch(
                                              value: switchStates[
                                                  index], // Use specific state for each switch
                                              activeColor: Colors.green,
                                              inactiveTrackColor:
                                                  Colors.grey[400],
                                              inactiveThumbColor: Colors.white,
                                              onChanged: (bool value) {
                                                setState(() {
                                                  switchStates[index] =
                                                      value; // Update the state of the specific switch
                                                  print(
                                                      "Switch ${index + 1} changed to: $value"); // Print the switch state (true/false)
                                                });
                                              },
                                            ),
                                          )
                                        ],
                                      ),
                                      Divider(thickness: 1, color: Colors.grey),
                                      SizedBox(height: 5),

                                      // Row 2: Account Alice
                                      _buildRow("Account Alice",
                                          '${matchedClients[index]['account_alice'].length > 10 ? matchedClients[index]['account_alice'].substring(0, 10) + '..' : matchedClients[index]['account_alice']}'),

                                      // Row 3: Name
                                      _buildRow(
                                        "Name",
                                        matchedClients[index]['name'].length >
                                                10
                                            ? matchedClients[index]['name']
                                                    .substring(0, 10) +
                                                '..'
                                            : matchedClients[index]['name'],
                                      ),

                                      // Row 4: Client ID
                                      _buildRow("Client ID",
                                          '${matchedClients[index]['clientid']}'),

                                      // Row 5: Date
                                      _buildRow("Date",
                                          '${matchedClients[index]['date']}'),

                                      SizedBox(height: 10),

                                      // Delete Button
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: IconButton(
                                          icon: Icon(Icons.delete,
                                              color: Colors.white),
                                          onPressed: () {
                                            deleteBroker(
                                                index,
                                                matchedClients != null
                                                    ? matchedClients[index]
                                                        ['clientid']
                                                    : matchedClients[index]
                                                        ['clientid']);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String title, String value) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
            ),
            Text(
              value,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 17),
            ),
          ],
        ),
        Divider(thickness: 1, color: Colors.grey),
        SizedBox(height: 5),
      ],
    );
  }
}
