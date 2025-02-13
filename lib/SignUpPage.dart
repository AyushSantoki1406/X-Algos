import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:xalgo/HomePage.dart';
import 'package:xalgo/SignInPage.dart';
import 'package:xalgo/secret/secret.dart';
import 'package:xalgo/theme/app_colors.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

String getOperatingSystem() {
  if (kIsWeb) {
    return "Web";
  } else {
    return Platform.operatingSystem;
  }
}

void main() {
  runApp(const SignUpPage());
}

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SignUp(),
      theme: ThemeData.dark(useMaterial3: true),
    );
  }
}

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  bool isLoading = false;
  int currentIndex = 0;

  String? realGmailOtp;
  String? realMobileOtp;

  int _emailSecondsRemaining = 30;
  int _mobileSecondsRemaining = 30;
  bool _isEmailResendAvailable = true;
  bool _isMobileResendAvailable = true;
  Timer? _emailTimer;
  Timer? _mobileTimer;

  TextEditingController _fname = TextEditingController();
  TextEditingController _lname = TextEditingController();
  TextEditingController _email = TextEditingController();
  TextEditingController _phoneNo = TextEditingController();
  TextEditingController _referCode = TextEditingController();
  TextEditingController _pin = TextEditingController();
  TextEditingController _confirmPin = TextEditingController();

  final List<FocusNode> gmailOtpFocusNodes =
      List.generate(6, (_) => FocusNode());
  final List<TextEditingController> gmailOtpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> mobileOtpFocusNodes =
      List.generate(6, (_) => FocusNode());
  final List<TextEditingController> mobileOtpControllers =
      List.generate(6, (_) => TextEditingController());

  bool isGmailOtpWrong = false;
  bool isMobileOtpWrong = false;

  void _startEmailTimer() {
    if (!_isEmailResendAvailable) return;

    // Call API for email OTP
    fetchStep1Data(
      "${Secret.backendUrl}/signup-step-1", // Step 1 API endpoint
      {
        "email": _email.text,
        "firstName": _fname.text,
        "lastName": _lname.text,
        "phone": _phoneNo.text,
        "referralCode": _referCode.text,
      },
    );

    setState(() {
      _isEmailResendAvailable = false;
      _emailSecondsRemaining = 30;
    });

    _emailTimer?.cancel();
    _emailTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_emailSecondsRemaining > 0) {
        setState(() {
          _emailSecondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isEmailResendAvailable = true;
        });
      }
    });
  }

  void _startMobileTimer() {
    if (!_isMobileResendAvailable) return;

    // Call API for mobile OTP
    fetchStep1Data(
      "${Secret.backendUrl}/signup-step-1",
      {
        "email": _email.text,
        "firstName": _fname.text,
        "lastName": _lname.text,
        "phone": _phoneNo.text,
        "referralCode": _referCode.text,
      },
    );

    setState(() {
      _isMobileResendAvailable = false;
      _mobileSecondsRemaining = 30;
    });

    _mobileTimer?.cancel();
    _mobileTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_mobileSecondsRemaining > 0) {
        setState(() {
          _mobileSecondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isMobileResendAvailable = true;
        });
      }
    });
  }

  Future<void> fetchStep1Data(String route, Map<String, dynamic> body) async {
    setState(() {
      isLoading = true;
    });
    print(_email.text.isNotEmpty);

    if (_email.text.isNotEmpty &&
        _fname.text.isNotEmpty &&
        _lname.text.isNotEmpty &&
        _phoneNo.text.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse(route),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode(body),
        );

        final Map<String, dynamic> response2 = jsonDecode(response.body);
        print(response2);
        if (response2['email'] == false) {
          print("Email already exist!");
        } else if (response2['number'] == false) {
          print("Number already exist!");
        } else if (response2['Referr'] == false) {
          print("Wrong Referral Code");
        } else if (response2['Referr']) {
          realGmailOtp = response2['gmailOtp'];
          realMobileOtp = response2['mobileNumberOtp'];
          print(realGmailOtp);
          print(realMobileOtp);
        } else {
          print(">>>>>>>>>>>>");
        }
      } catch (e) {
        print("Exception occurred: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred: $e")),
        );
      } finally {
        setState(() {
          currentIndex++;
          isLoading:
          false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailTimer?.cancel();
    _mobileTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchStep3Data(String route, Map<String, dynamic> body) async {
    if (_pin.text.isNotEmpty && _confirmPin.text.isNotEmpty) {
      if (_pin.text == _confirmPin.text) {
        print("Pin: ${_pin.text}");
        print("Confirm Pin: ${_confirmPin.text}");
        try {
          final response = await http.post(
            Uri.parse(route),
            headers: {
              "Content-Type": "application/json",
            },
            body: jsonEncode(body),
          );

          final Map<String, dynamic> response2 = jsonDecode(response.body);

          // Process the response if needed
          print("Response: $response2");
          if (response2['signup']) {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => SignIn()));
          }
        } catch (e) {
          print("Error: $e");
        } finally {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        print("Pins do not match");
      }
    } else {
      print("Pin or Confirm Pin not entered");
    }
  }

  String getGmailOtp() {
    return gmailOtpControllers.map((controller) => controller.text).join();
  }

  String getMobileOtp() {
    return mobileOtpControllers.map((controller) => controller.text).join();
  }

  void handlecheck() {
    String gmailOtp = getGmailOtp();
    String mobileOtp = getMobileOtp();
    print('Gmail OTP: $gmailOtp');
    print('Mobile OTP: $mobileOtp');
    print('Gmail OTP: $realGmailOtp');
    print('Mobile OTP: $realMobileOtp');

    setState(() {
      // Validate Gmail OTP
      if (gmailOtp.toString() == realGmailOtp.toString()) {
        isGmailOtpWrong = false; // Correct Gmail OTP
      } else {
        isGmailOtpWrong = true; // Incorrect Gmail OTP
      }

      // Validate Mobile OTP
      if (mobileOtp.toString() == realMobileOtp.toString()) {
        isMobileOtpWrong = false; // Correct Mobile OTP
      } else {
        isMobileOtpWrong = true; // Incorrect Mobile OTP
      }

      // Proceed if both OTPs are correct
      if (!isGmailOtpWrong && !isMobileOtpWrong) {
        setState(() {
          currentIndex++;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      // Step 1 Content
      SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(context).viewInsets.bottom, // Adjust for keyboard
          ),
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
                            "First Name",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        SizedBox(
                          height: 7,
                        ),
                        TextField(
                          controller: _fname,
                          decoration: InputDecoration(
                            labelText: "First Name",
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
                      height: 15,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              left: 5), // Adjust padding as needed
                          child: Text(
                            "Last Name",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        SizedBox(
                          height: 7,
                        ),
                        TextField(
                          controller: _lname,
                          decoration: InputDecoration(
                            labelText: "Last Name",
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
                      height: 15,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              left: 5), // Adjust padding as needed
                          child: Text(
                            "Email",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        SizedBox(
                          height: 7,
                        ),
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType
                              .emailAddress, // Shows email-specific keyboard
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: "Email",
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
                      height: 15,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              left: 5), // Adjust padding as needed
                          child: Text(
                            "Phone",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        SizedBox(
                          height: 7,
                        ),
                        TextField(
                          controller: _phoneNo,
                          inputFormatters: [
                            FilteringTextInputFormatter
                                .digitsOnly, // Allows only digits
                            LengthLimitingTextInputFormatter(
                                10), // Limits to 10 characters
                          ],
                          decoration: InputDecoration(
                            labelText: "Enter Phone Number",
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
                      height: 15,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              left: 5), // Adjust padding as needed
                          child: Text(
                            "Referral Code(optional)",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        SizedBox(
                          height: 7,
                        ),
                        TextField(
                          controller: _referCode,
                          decoration: InputDecoration(
                            labelText: "Enter Referral Code",
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
                            : () {
                                setState(() {
                                  isLoading = true;
                                });

                                fetchStep1Data(
                                  "${Secret.backendUrl}/signup-step-1",
                                  {
                                    "email": _email.text,
                                    "firstName": _fname.text,
                                    "lastName": _lname.text,
                                    "phone": _phoneNo.text,
                                    "referralCode": _referCode.text,
                                  },
                                ).then((_) {
                                  setState(() {
                                    isLoading = false;
                                    // currentIndex++; // Uncomment if you want to move to the next step
                                  });
                                }).catchError((error) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  print(
                                      "Error fetching data: $error"); // Handle error (show Snackbar, etc.)
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
                                  color: Color(0xFF1A1A1A),
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
                        Text("Already have an account?"),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      SignInPage()), // Replace with your target page
                            );
                          },
                          child: Text(
                            "  Sign In here",
                            style: TextStyle(color: AppColors.yellow),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Step 2 Content
      SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(context).viewInsets.bottom, // Adjust for keyboard
          ),
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
                      'Gmail OTP',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey, // Grey label color
                      ),
                    ),
                    SizedBox(height: 10),
                    OtpInputRow(
                      focusNodes: gmailOtpFocusNodes,
                      controllers: gmailOtpControllers,
                      isOtpWrong: isGmailOtpWrong, // Pass the validation flag
                    ),
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
                      isOtpWrong: isMobileOtpWrong, // Pass the validation flag
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          handlecheck();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.yellow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        child: Text(
                          "Next",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            if (currentIndex > 0) {
                              currentIndex--;
                            }
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
                        child: Text(
                          "Back",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Already have an account?"),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      SignInPage()), // Replace with your target page
                            );
                          },
                          child: Text(
                            "  Sign In here",
                            style: TextStyle(color: AppColors.yellow),
                          ),
                        ),
                      ],
                    ),
                    Text("$realGmailOtp"),
                    Text("$realMobileOtp"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Step 3 Content
      SingleChildScrollView(
        child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context)
                  .viewInsets
                  .bottom, // Adjust for keyboard
            ),
            child: Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.only(left: 5), // Adjust padding as needed
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
                    Padding(
                      padding:
                          EdgeInsets.only(left: 5), // Adjust padding as needed
                      child: Text(
                        "Confirm Pin",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(
                      height: 7,
                    ),
                    TextField(
                      controller: _confirmPin,
                      inputFormatters: [
                        FilteringTextInputFormatter
                            .digitsOnly, // Allows only digits
                        LengthLimitingTextInputFormatter(
                            4), // Limits to 10 characters
                      ],
                      decoration: InputDecoration(
                        labelText: "Confirm Pin",
                        labelStyle: TextStyle(
                          fontSize: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7.2),
                        ),
                        filled: true,
                        hintStyle: TextStyle(color: Colors.amber),
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
                            ? null // Disable button when loading
                            : () {
                                setState(() {
                                  isLoading = true;
                                });

                                fetchStep3Data(
                                  "${Secret.backendUrl}/signup-step-3",
                                  {
                                    "email": _email.text,
                                    "firstName": _fname.text,
                                    "lastName": _lname.text,
                                    "phone": _phoneNo.text,
                                    "referralCode": _referCode.text,
                                    "pin": _pin.text
                                  },
                                ).then((_) {
                                  setState(() {
                                    isLoading = false;
                                    currentIndex++;
                                  });
                                }).catchError((error) {
                                  setState(() {
                                    isLoading =
                                        false; // Ensure loading is false even on error
                                  });
                                  print("Error fetching data: $error");
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
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black, // Change color as needed
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
                    SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Already have an account?"),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      SignInPage()), // Replace with your target page
                            );
                          },
                          child: Text(
                            "  Sign In here",
                            style: TextStyle(color: AppColors.yellow),
                          ),
                        ),
                      ],
                    )
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
            margin: EdgeInsets.only(top: 20, bottom: 30),
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
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 2500),
                                      curve: Curves
                                          .easeInOut, // Smoother curve for transitions
                                      child: GestureDetector(
                                        child: Transform.scale(
                                          scale: currentIndex == index
                                              ? 1.0
                                              : 1.0, // Scale effect for the current step
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
                                                        .white, // White text for upcoming steps
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (index < 2) // Connecting line
                                      TweenAnimationBuilder(
                                        duration:
                                            const Duration(milliseconds: 500),
                                        tween: ColorTween(
                                          begin: Colors.white,
                                          end: currentIndex > index
                                              ? AppColors
                                                  .yellow // Yellow for completed lines
                                              : Colors.grey,
                                        ),
                                        builder: (context, Color? color, _) {
                                          return Container(
                                            width: 90,
                                            height: 2,
                                            color: color,
                                          );
                                        },
                                      )
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
                          child: pages[currentIndex.clamp(
                              0, pages.length - 1)], // Clamp to valid range
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

  const OtpInputRow({
    super.key,
    required this.focusNodes,
    required this.controllers,
    required this.isOtpWrong,
  });

  void _handlePaste(String pastedText) {
    if (pastedText.length == 6) {
      for (int i = 0; i < 6; i++) {
        controllers[i].text = pastedText[i];
      }
      focusNodes[5].unfocus(); // Move focus out after pasting
    }
  }

  void _clearAll() {
    for (var controller in controllers) {
      controller.clear();
    }
    focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 45,
          child: GestureDetector(
            onLongPress: _clearAll, // Clear all fields on long press
            child: RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: (RawKeyEvent event) {
                if (event is RawKeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.backspace &&
                    controllers[index].text.isEmpty &&
                    index > 0) {
                  focusNodes[index - 1].requestFocus();
                }
              },
              child: TextField(
                controller: controllers[index],
                focusNode: focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                style: TextStyle(color: Colors.white, fontSize: 18),
                onChanged: (value) {
                  if (value.length == 6) {
                    _handlePaste(value);
                    return;
                  }
                  if (value.isNotEmpty && index < 5) {
                    focusNodes[index + 1].requestFocus();
                  }
                },
                onTap: () {
                  if (isOtpWrong) {
                    HapticFeedback.vibrate(); // Vibrate on wrong OTP
                  }
                },
              ),
            ),
          ),
        );
      }),
    );
  }
}
