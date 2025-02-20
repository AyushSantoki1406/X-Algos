import 'dart:async';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xalgo/HomePage.dart';
import 'package:xalgo/SignUpPage.dart';
import 'package:xalgo/main.dart';
import 'package:xalgo/secret/secret.dart';
import 'package:xalgo/theme/app_colors.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:toastification/toastification.dart';

void main() {
  runApp(const SignInPage());
}

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SignIn(),
      theme: ThemeData.dark(useMaterial3: true),
    );
  }
}

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> with SingleTickerProviderStateMixin {
  bool isLoading = false;
  int currentIndex = 0;
  bool isOtpWrong = false;

  TextEditingController _controller = TextEditingController();
  TextEditingController _pin = TextEditingController();
  String realOTP = "";

  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;

  int _secondsRemaining = 30;
  bool _isResendAvailable = true;
  Timer? _timer;
  bool _isResendClicked = false;
  bool isSessionActive = false;

  final dio = Dio();
  final cookieJar = CookieJar(); // Store cookies

  void setupDio() {
    dio.interceptors.add(CookieManager(cookieJar));
  }

  @override
  void initState() {
    super.initState();

    checkSession();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_animationController);
  }

  Future<String?> getEmail() async {
    try {
      String? email = await secureStorage.read(key: 'Email');
      String? userSchemaJson = await secureStorage.read(key: "backendData");

      if (userSchemaJson != null) {
        Map<String, dynamic> userData = jsonDecode(userSchemaJson);
      } else {
        print('No backendData found in storage.');
      }

      return email;
    } catch (e) {
      print('Error fetching email: $e');
      return null;
    }
  }

  Future<void> checkSession() async {
    final url = '${Secret.backendUrl}/check-session';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data);
      if (data['activeSession'] == false) {
        print('Session expired');
      } else {
        isSessionActive = true;
        _controller = data['user']['clientId'];
        currentIndex++;
        print(data['user']['clientId']);
        print('Session is valid');
      }
    } else {
      print('Error checking session');
    }
  }

  void triggerShakeAnimation() {
    _animationController
        .forward(from: 0)
        .then((_) => _animationController.stop());
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  final List<FocusNode> mobileOtpFocusNodes =
      List.generate(6, (_) => FocusNode());
  final List<TextEditingController> mobileOtpControllers =
      List.generate(6, (_) => TextEditingController());

  String getMobileOtp() {
    return mobileOtpControllers.map((controller) => controller.text).join();
  }

  Future<String> getUserAgent() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String userAgent = '';

    if (kIsWeb) {
      userAgent = 'Web'; // You can customize this for web if needed
    } else if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      userAgent =
          'Android ${androidInfo.version.release}; ${androidInfo.model} Build/${androidInfo.version.codename})';
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      userAgent =
          'iPhone OS ${iosInfo.systemVersion.replaceAll('.', '_')} like Mac OS X)';
    }

    return userAgent;
  }

  Future<void> fetchStep1Data(String route, Map<String, dynamic> body) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(route),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );
      print(_controller.text);
      print("Response from Step 1: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // If canSendOtp is true, proceed to Step 2
        if (responseData['canSendOtp'] == true) {
          toastification.show(
            context: context,
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.lightGreenAccent),
                SizedBox(width: 10),
                Text('Wow so easy!', style: TextStyle(color: Colors.black)),
              ],
            ),
            autoCloseDuration: Duration(milliseconds: 3000),
            backgroundColor: Colors.white, // Light theme color
            closeOnClick: false,
            pauseOnHover: true,
          );
          setState(() {
            fetchStep2Data("${Secret.backendUrl}/signin-step-2");
            currentIndex++; // Move to the next step
          });
        }
      } else {
        print("Error: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.body}")),
        );
      }
    } catch (e) {
      print("Exception occurred: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _startTimer() {
    if (!_isResendAvailable) return;

    // Call the API when user clicks "Resend OTP"
    fetchStep2Data("${Secret.backendUrl}/signin-step-2");

    setState(() {
      _isResendAvailable = false;
      _isResendClicked = true;
      _secondsRemaining = 30;
    });

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isResendAvailable = true;
          _isResendClicked = false;
        });
      }
    });
  }

  // Step 2 API Call - Fetch OTP
  Future<void> fetchStep2Data(String route) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(route),
        headers: {
          "Content-Type": "application/json",
        },
      );
      print("Response from Step 2: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        // Print OTP if available
        if (responseData['otp'] != null) {
          realOTP = responseData['otp'];
        } else {
          print("OTP not found in response from Step 2");
        }
      } else {
        print("Error: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.body}")),
        );
      }
    } catch (e) {
      print("Exception occurred: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> verifyPin(
      BuildContext context, TextEditingController _pin) async {
    String userAgent = await getUserAgent();

    String url = "${Secret.backendUrl}/verify-pin";
    print(_pin.text);
    // The request body with the user agent
    Map<String, dynamic> body = {
      "userInput": _controller.text, // Use _pin.text to get the text value
      "deviceInfo": userAgent,
      "pin": _pin.text, // Use _pin.text directly
    };

    // Make the API request
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
        body: json.encode(body), // Ensure the body is properly encoded
      );

      // Decode response body
      final Map<String, dynamic> a = jsonDecode(response.body);

      if (a['pin'] != false && a['userSchema'] is Map<String, dynamic>) {
        // Access user schema data
        final String email = a['userSchema']['Email'] ?? "Unknown";
        final Map<String, dynamic> userData = a['userSchema'];
        String userSchemaJson = jsonEncode(userData);
        print("User Email: $email");
        print("User Name: ${a['userSchema']['Name']}");

        // Save email in secure storage
        await secureStorage.write(key: 'Email', value: email);
        await secureStorage.write(key: 'backendData', value: userSchemaJson);

        // Send login mail
        await sendLoginMail(email, userAgent);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        // Navigate to the Home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => Home()), // Replace Home with your widget
        );
      } else {
        print("Failed to verify pin: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> sendLoginMail(String email, String userAgent) async {
    final String url = '${Secret.backendUrl}/sendLoginMail';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'Email': email,
          'deviceInfo': userAgent,
        }),
      );

      if (response.statusCode == 200) {
        print('Mail sent successfully: ${response.body}');
      } else {
        print('Failed to send mail: ${response.statusCode}');
      }
    } catch (error) {
      print('Error sending mail: $error');
    }
  }

  void checkOTP() {
    final otp = getMobileOtp();
    print("Entered OTP: $otp, Real OTP: $realOTP");

    setState(() {
      if (otp == realOTP) {
        print("OTP is correct.");
        isOtpWrong = false; // Correct OTP
        currentIndex++;
      } else {
        print("OTP is incorrect.");
        isOtpWrong = true; // Incorrect OTP
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      // Step 1 Content
      Container(
        padding: EdgeInsets.only(top: 10),
        child: Column(
          children: [
            Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                            left: 5), // Adjust padding as needed
                        child: Text(
                          "Client ID or Mobile Number",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SizedBox(
                        height: 7,
                      ),
                      TextField(
                        controller: _controller,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(
                              10), // Limits to 10 characters
                        ],
                        decoration: InputDecoration(
                          labelText: "Enter Client ID or Mobile No",
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
                            borderSide: BorderSide(
                                color: Color(0xFF3D3E57), width: 0.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7.2),
                            borderSide: BorderSide(
                                color: Color(0xFF3D3E57), width: 0.5),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 10),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              setState(() {
                                isLoading = true;
                              });

                              await fetchStep1Data(
                                "${Secret.backendUrl}/signin-step-1",
                                {"userInput": _controller.text},
                              );

                              setState(() {
                                isLoading = false;
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.yellow,
                              ),
                            )
                          : const Text(
                              "Proceed",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("New on our platform?"),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SignUp()),
                          );
                        },
                        child: Text(
                          " Create an account",
                          style: TextStyle(color: AppColors.yellow),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Step 2 Content
      Container(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify your Gmail and Mobile OTP',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white, // White text for dark mode
                  fontWeight: FontWeight.w600,
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Text(
                      'Mobile OTP',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey, // Grey label color
                      ),
                    ),
                    SizedBox(height: 10),
                    OtpInputRow(
                      focusNodes: mobileOtpFocusNodes,
                      controllers: mobileOtpControllers,
                      isOtpWrong: isOtpWrong,
                      animation: _shakeAnimation,
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                setState(() {
                                  isLoading = true;
                                });

                                checkOTP();

                                setState(() {
                                  isLoading = false;
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.yellow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.yellow,
                                ),
                              )
                            : const Text(
                                "Next",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _isResendAvailable ? _startTimer : null,
                          child: Text(
                            _isResendClicked
                                ? "Resend in $_secondsRemaining sec"
                                : "Resend OTP",
                            style: TextStyle(
                              color: AppColors.yellow,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )),
                    Text("OTP is $realOTP")
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Step 3 Content
      Container(
        child: Center(
            child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 5), // Adjust padding as needed
                  child: Text(
                    "Pin",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(
                  height: 7,
                ),
                TextField(
                  controller: _pin,
                  inputFormatters: [
                    FilteringTextInputFormatter
                        .digitsOnly, // Allows only digits
                    LengthLimitingTextInputFormatter(
                        4), // Limits to 10 characters
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
                      borderSide:
                          BorderSide(color: Color(0xFF3D3E57), width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7.2),
                      borderSide:
                          BorderSide(color: Color(0xFF3D3E57), width: 0.5),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            setState(() {
                              isLoading = true;
                            });

                            await verifyPin(context,
                                _pin); // Use await only if verifyPin returns a Future

                            setState(() {
                              isLoading = false;
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.yellow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.yellow,
                            ),
                          )
                        : const Text(
                            "Submit",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
              ],
            ),
          ],
        )),
      ),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(10),
            margin: EdgeInsets.only(top: 30, bottom: 30),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
              color: Color(0xFF1A1A1A),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        children: [
                          Container(
                            margin: EdgeInsets.only(top: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                3,
                                (index) => Row(
                                  children: [
                                    GestureDetector(
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        margin: const EdgeInsets.all(10),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: currentIndex >= index
                                              ? AppColors
                                                  .yellow // Yellow color for completed/current steps
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: AppColors
                                                .yellow, // Border color
                                            width: 2.0,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: currentIndex >= index
                                                ? Colors
                                                    .black // Black text for completed steps
                                                : Colors
                                                    .white, // Black text for white steps
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (index < 2) // Connecting line
                                      Container(
                                        width: 90,
                                        height: 2,
                                        color: currentIndex > index
                                            ? AppColors
                                                .yellow // Purple for completed lines
                                            : Colors
                                                .white, // Default white for upcoming lines
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(
                        height: 40,
                      ),
                      Container(
                        padding: const EdgeInsets.only(bottom: 30),
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome to X-Algos! 👋",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "Please sign up to create a new account",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Page content
                      Flexible(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child:
                              pages[currentIndex], // Display the current page
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OtpInputRow extends StatelessWidget {
  final List<FocusNode> focusNodes;
  final List<TextEditingController> controllers;
  final bool isOtpWrong;
  final Animation<double> animation;

  const OtpInputRow({
    super.key,
    required this.focusNodes,
    required this.controllers,
    required this.isOtpWrong,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(animation.value, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          6,
          (index) => SizedBox(
            width: 45,
            child: RawKeyboardListener(
              focusNode: FocusNode(), // FocusNode for the RawKeyboardListener
              onKey: (event) {
                // Detect backspace key press
                if (event is RawKeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.backspace) {
                  if (controllers[index].text.isEmpty && index > 0) {
                    // Move focus to the previous field if empty
                    focusNodes[index - 1].requestFocus();
                  }
                }
              },
              child: TextField(
                controller: controllers[index],
                focusNode: focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                decoration: InputDecoration(
                  counterText: "",
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isOtpWrong ? Colors.red : Colors.white,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isOtpWrong ? Colors.red : AppColors.yellow,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    // Move focus to the next field if input is entered
                    focusNodes[index + 1].requestFocus();
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
