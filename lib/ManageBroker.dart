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
  late Map<String, dynamic> userSchema;
  Map<String, dynamic> clientData = {};
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
      print("fetching emaail");
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

      var responseBody = json.decode(dbSchemaResponse.body);
      print(
          'Response Body: $responseBody'); // Log the response to see its structure.

      if (dbSchemaResponse.statusCode == 200) {
        var responseBody = json.decode(dbSchemaResponse.body);

        // Ensure responseBody is a Map<String, dynamic>
        if (responseBody is Map<String, dynamic>) {
          setState(() {
            userSchema = responseBody; // Update userSchema if needed
          });

          // Extract client data (Assuming it's a Map<String, dynamic>)
          Map<String, dynamic> clientData = userSchema;

          // Extract AngelBrokerData and DeltaBrokerSchema as lists
          List<dynamic> angelBrokerData = clientData['AngelBrokerData'] ?? [];
          List<dynamic> deltaBrokerSchema =
              clientData['DeltaBrokerSchema'] ?? [];

          // Print the extracted data
          print('Client Data: $clientData');
          print('Angel Broker Data: $angelBrokerData');
          print('Delta Broker Schema: $deltaBrokerSchema');

          // Optionally, print individual elements
          if (angelBrokerData.isNotEmpty) {
            print('First Angel Broker Data: ${angelBrokerData[0]}');
          }
          if (deltaBrokerSchema.isNotEmpty) {
            print('Delta Broker Schema: $deltaBrokerSchema');
          }
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
      drawer: AppDrawer(),
      endDrawer: AppDrawer(),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {},
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Color(0xFF000000),
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
                    tableLoader
                        ? Column(
                            children: List.generate(
                              4,
                              (index) => Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  height: 60,
                                  width: double.infinity,
                                  margin: EdgeInsets.symmetric(vertical: 8),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            margin: EdgeInsets.only(top: 16),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Theme.of(context).cardColor,
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columnSpacing: 20,
                                columns: [
                                  DataColumn(
                                      label: Center(child: Text('Client ID'))),
                                  DataColumn(
                                      label:
                                          Center(child: Text('Account Alias'))),
                                  DataColumn(
                                      label: Center(child: Text('Name'))),
                                  DataColumn(
                                      label: Center(child: Text('Date'))),
                                  DataColumn(
                                      label:
                                          Center(child: Text('Broker Name'))),
                                  DataColumn(
                                      label: Center(child: Text('Action'))),
                                ],
                                rows: clientData.entries
                                    .map((MapEntry<String, dynamic> entry) {
                                  // Access the value of the entry
                                  var item = entry.value;
                                  print(item);
                                  String clientId = item['userData']?['data']
                                          ?['clientcode'] ??
                                      item['balances']?['result'][0]
                                          ?['user_id'] ??
                                      "N/A";

                                  String accountAlias = item['userData']
                                          ?['data']?['clientcode'] ??
                                      item['balances']?['result'][0]
                                          ?['user_id'] ??
                                      "N/A";

                                  String name = item['userData']?['data']
                                              ?['name']
                                          ?.toUpperCase() ??
                                      ((item['userDetails']?['result']
                                                      ?['first_name'] ??
                                                  "N/A") +
                                              " " +
                                              (item['userDetails']?['result']
                                                      ?['last_name'] ??
                                                  "N/A"))
                                          .toUpperCase();

                                  String date =
                                      "N/A"; // Customize as per your schema

                                  String brokerName = item['userData'] != null
                                      ? "AngelOne"
                                      : item['deltaApiKey'] != null
                                          ? "Delta"
                                          : "Loading...";

                                  return DataRow(cells: [
                                    DataCell(Center(child: Text(clientId))),
                                    DataCell(Center(child: Text(accountAlias))),
                                    DataCell(Center(
                                        child: Text(
                                      name,
                                      overflow: TextOverflow.ellipsis,
                                    ))),
                                    DataCell(Center(child: Text(date))),
                                    DataCell(Center(child: Text(brokerName))),
                                    DataCell(
                                      Center(
                                          // child: IconButton(
                                          //   icon: Icon(Icons.delete,
                                          //       color: Colors.red),
                                          //   onPressed: () => deleteBrokerFunction(
                                          //       clientData.indexOf(item), clientId),
                                          // ),
                                          ),
                                    ),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
