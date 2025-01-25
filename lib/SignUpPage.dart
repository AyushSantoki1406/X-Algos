import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:xalgo/HomePage.dart';
import 'package:xalgo/SignInPage.dart';
import 'package:xalgo/app_colors.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  TextEditingController _fname = TextEditingController();
  TextEditingController _lname = TextEditingController();
  TextEditingController _email = TextEditingController();
  TextEditingController _phoneNo = TextEditingController();
  TextEditingController _referCode = TextEditingController();
  TextEditingController _pin = TextEditingController();
  TextEditingController _confirmPin = TextEditingController();

  final List<FocusNode> gmailOtpFocusNodes =
      List.generate(6, (index) => FocusNode());
  final List<FocusNode> mobileOtpFocusNodes =
      List.generate(6, (index) => FocusNode());

  final List<TextEditingController> gmailOtpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<TextEditingController> mobileOtpControllers =
      List.generate(6, (index) => TextEditingController());

  String getGmailOtp() {
    return gmailOtpControllers.map((controller) => controller.text).join();
  }

  String getMobileOtp() {
    return mobileOtpControllers.map((controller) => controller.text).join();
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
          setState(() {
            currentIndex++;
          });
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
          isLoading:
          false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    // Define pages dynamically based on currentIndex
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
                              // Set loading to true when initiating the request
                              setState(() {
                                isLoading = true;
                              });

                              fetchStep1Data(
                                "https://oyster-app-4y3eb.ondigitalocean.app/signup-step-1", // Step 1 API endpoint
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
                                  // currentIndex++; // Move to the next step
                                });
                              }).catchError((error) {
                                setState(() {
                                  isLoading =
                                      false; // Ensure loading is false even on error
                                });
                                // Handle the error here, show a snack bar or other UI feedback
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
                      child: const Text(
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
      // Step 2 Content
      Container(
        child: Center(
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
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          String gmailOtp = getGmailOtp();
                          String mobileOtp = getMobileOtp();
                          print('Gmail OTP: $gmailOtp');
                          print('Mobile OTP: $mobileOtp');
                          print('Gmail OTP: $realGmailOtp');
                          print('Mobile OTP: $realMobileOtp');

                          if (gmailOtp.toString() == realGmailOtp.toString() ||
                              mobileOtp.toString() ==
                                  realMobileOtp.toString()) {
                            setState(() {
                              currentIndex++;
                            });
                          } else {
                            print("OTP is wrong");
                          }
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
                    )
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
                Padding(
                  padding: EdgeInsets.only(left: 5), // Adjust padding as needed
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
                        ? null
                        : () {
                            // Set loading to true when initiating the request
                            setState(() {
                              isLoading = true;
                            });

                            fetchStep3Data(
                              "https://oyster-app-4y3eb.ondigitalocean.app/signup-step-3", // Step 1 API endpoint
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
                              // Handle the error here, show a snack bar or other UI feedback
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
                    child: Text(
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
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
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
    );
  }
}

class OtpInputRow extends StatelessWidget {
  final List<FocusNode> focusNodes;
  final List<TextEditingController> controllers;

  const OtpInputRow(
      {super.key, required this.focusNodes, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 45,
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
              decoration: InputDecoration(
                counterText: "",
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.yellow, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: TextStyle(color: Colors.white, fontSize: 18),
              onChanged: (value) {
                if (value.isNotEmpty && index < 5) {
                  focusNodes[index + 1].requestFocus();
                }
              },
            ),
          ),
        );
      }),
    );
  }
}
