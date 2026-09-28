import 'dart:convert';
import 'dart:math';
import 'package:edge_alerts/edge_alerts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:swiftbook_ai/AccountCreatedScreen.dart';
import 'package:swiftbook_ai/Global.dart';
import 'package:swiftbook_ai/login_page.dart';

import 'main.dart';

class EmailVerificationScreen extends StatefulWidget {
  @override
  _EmailVerificationScreenState createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  String code = "";

  TextEditingController codeController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState

    code = generate6DigitCode();

    sendVerificationEmail(code);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Email Verification',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10.0),
              Text(
                'Verification code sent to your email',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 20.0),
              PinCodeTextField(
                textStyle: TextStyle(color: Colors.white),
                appContext: context,
                length: 6,
                onChanged: (value) {},
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(5),
                  fieldHeight: 50,
                  fieldWidth: 40,
                  activeFillColor: Colors.white,
                ),
                controller: codeController,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  // Add your verification logic here

                  if (codeController.text == code) {
                    register();

                   }
                  else {
                    Fluttertoast.showToast(msg: "Incorrect code try again");
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  // Sets the background color to blue
                  foregroundColor: Colors.white,
                  // Ensures any icons or default text colors are white
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 12,
                  ),
                  // Optional: makes the button look nice and spacious
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      8,
                    ), // Optional: rounds the corners slightly to match your theme
                  ),
                ),
                child: const Text(
                  'Verify Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 10.0),
              TextButton(
                onPressed: () {
                  code = generate6DigitCode();
                  sendVerificationEmail(code);
                },
                child: Text(
                  'Didn\'t get the code? Check spam or resend.',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future register() async {
    try {
      showCircularProgress(context);

      var url = Uri.parse(
        "https://securenet.justyes.co.uk/Prod/SwiftBooksApis/registerClients.php",
      );

      var response = await http.post(
        url,
        body: {
          "db_key": "R.kieZ",
          "firstName": firstName,
          "middleName": middleName,
          "lastName": lastName,
          "businessName": businessName,
          "postCode": postCode,
          "address": address,
          "email": clientEmail,
          "phoneNumber": clientContact,
          "password": password,
        },
      );

      if (response.statusCode == 200) {
        debugPrint("Response: ${response.body}");
        var data = json.decode(response.body);

        if (data == "SUCCESS") {

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AccountCreatedScreen(),
            ),
          );

        } else if (data == "EXISTS") {
          edgeAlert(
            context,
            title: 'Account already exists',
            description:
            'Please log in using your registered email and password.',
            gravity: Gravity.bottom,
            duration: 4,
            icon: Icons.warning,
            backgroundColor: Colors.orange,
          );
          Navigator.pop(context);
        } else {
          Fluttertoast.showToast(msg: "Server error: $data");
          Navigator.pop(context);
        }
      } else {
        print("HTTP error ${response.statusCode}: ${response.body}");
        Fluttertoast.showToast(msg: "Unexpected error occurred");
        Navigator.pop(context);
      }
    } catch (error) {
      Fluttertoast.showToast(msg: "Something went wrong");
      print("Error: $error");
      Navigator.pop(context);
    }
  }

  String generate6DigitCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<bool> sendVerificationEmail(String verificationCode) async {
    const String url =
        'https://securenet.justyes.co.uk/Prod/SwiftBooksApis/verification-email.php';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          "email": clientEmail,
          "verificationCode": verificationCode,
        },
      );

      if (response.statusCode == 200) {
        // PHP echoes success or error message
        // Fluttertoast.showToast(msg: "Verification code sent");
        debugPrint('Email Response: ${response.body}');
        return true;
      } else {
        debugPrint('Failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending email: $e');
      return false;
    }
  }

  void showCircularProgress(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      // Prevent the user from dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.blue),
        );
      },
    );
  }
}
