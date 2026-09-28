import 'dart:convert';
import 'dart:math';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class PhoneNumberVerificationScreen extends StatefulWidget {
  @override
  _PhoneNumberVerificationScreenState createState() => _PhoneNumberVerificationScreenState();
}

class _PhoneNumberVerificationScreenState extends State<PhoneNumberVerificationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  TextEditingController _otpController = TextEditingController();


  // TO DO: Replace with your actual PHP server URLs
  final String _sendUrl = 'https://securenet.justyes.co.uk/Prod/SwiftBooksApis/send-otp.php';
  final String _verifyUrl = 'https://securenet.justyes.co.uk/Prod/SwiftBooksApis/verify-otp.php';

  // This variable stores the verifyId returned by Bird via send-otp.php
  String? _currentVerifyId;

  bool _otpSent = false;
  bool _isLoading = false;


  @override
  void initState() {
    // TODO: implement initState

    _requestVerification();

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
                'Verify Your Mobile Number',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10.0),
              Text(
                'Verification code sent to your number',
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
                controller: _otpController,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  // Add your verification logic here
                  _confirmVerification();


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
                  _requestVerification();
                },
                child: Text(
                  'Didn\'t receive code? Request again',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestVerification() async {
    final phoneNumber = "+923418086878";
    if (phoneNumber.isEmpty) {
      _showSnack('Please enter a valid phone number.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_sendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phoneNumber}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _otpSent = true;
          // Capture and store the verification ID from our PHP backend
          _currentVerifyId = data['verifyId'];
        });
        _showSnack('OTP Sent Successfully!');
      } else {
        _showSnack(data['message'] ?? 'Failed to send OTP.');
      }
    } catch (e) {
      _showSnack('Network error: Could not reach backend server.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void showCircularProgress(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      // Prevent the user from dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.amber),
        );
      },
    );
  }

  // Step 2: Confirm the OTP
  Future<void> _confirmVerification() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      _showSnack('Please enter the OTP code.');
      return;
    }

    if (_currentVerifyId == null) {
      _showSnack('Missing verification context. Please request a new code.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_verifyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code,
          'verifyId': _currentVerifyId, // Send the ID back to PHP
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _showSnack('Success! Phone number is verified.');
        // Navigate to your main landing screen or update registration state
      } else {
        _showSnack(data['message'] ?? 'Incorrect OTP code.');
      }
    } catch (e) {
      _showSnack('Network error: Verification could not be completed.');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
