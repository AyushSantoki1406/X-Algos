import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:xalgo/widgets/drawer_widget.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Future<Map<String, dynamic>> fetchProfile() async {
    final url =
        Uri.parse('https://oyster-app-4y3eb.ondigitalocean.app/dbschema');

    final Map<String, String> body = {
      'Email': 'ayushsantoki1462004@gmail.com',
    };
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();

    Future<void> loadUserSchema() async {
      try {
        // Retrieve the JSON string from secure storage
        String? userSchemaJson = await secureStorage.read(key: 'backendData');

        if (userSchemaJson != null) {
          // Decode the JSON string back to a map
          Map<String, dynamic> userSchema = jsonDecode(userSchemaJson);

          print('User Name: ${userSchema}');
          print('User Email: ${userSchema['Email']}');
        } else {
          print('No user schema found in storage.');
        }
      } catch (e) {
        print('Error loading user schema: $e');
      }
    }

    loadUserSchema();

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load profile: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          centerTitle: true, // Center the title
          title: const Text(
            'Dashboard',
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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => AppDrawer()),
                  );
                },
              ),
            ),
          ],
        ),
        endDrawer: AppDrawer(),
        body: FutureBuilder<Map<String, dynamic>>(
          future: fetchProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                color: Color(0xFF1A1A1A),
                child: const Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            } else if (snapshot.hasData) {
              final data = snapshot.data!;
              return Container(
                width: double.infinity,
                color: Color(0xFF1A1A1A),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, right: 8),
                              child: Column(
                                children: [Text("P&L"), Text("₹")],
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, right: 8),
                              child: Column(
                                children: [
                                  Text("Capital"),
                                  Text(
                                    data['capital'] ?? '₹0.0',
                                    style: TextStyle(color: Color(0xFF4CAF50)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return const Center(
                child: Text('No data available'),
              );
            }
          },
        ),
      ),
    );
  }
}
