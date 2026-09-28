import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftbook_ai/signup_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Global.dart';
import 'dashboard.dart';
import 'main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isRemember = false;
  bool isObscure = true;

  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  // TextEditingController _emailController = TextEditingController(
  //   text: "hassan@gmail.com",
  // );
  // TextEditingController _passwordController = TextEditingController(
  //   text: "12345",
  // );

  String expiryDate = "";

  @override
  void initState() {
    loadUserData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(90, 20, 0, 0),
                  child: Image.asset('assets/images/grad2.png'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 100, 0),
                  child: Image.asset('assets/images/grad1.png'),
                ),
                Positioned(
                  top: 60,
                  left: 110,
                  child: Text(
                    'Swift Books AI',
                    style: GoogleFonts.lato(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  top: 120,
                  left: 10,
                  right: 10,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: 250,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 30),
                          Text(
                            "Login",
                            style: TextStyle(
                              color: Colors.blueAccent.shade100,
                              fontWeight: FontWeight.bold,
                              fontSize: 25,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Text(
                              "Enter your email and password to log in",
                              style: GoogleFonts.lato(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              cursorColor: Colors.white,
                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                    width: 0.8,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.blue,
                                    width: 0.8,
                                  ),
                                ),
                                labelText: " Email ",
                                labelStyle: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: TextField(
                              controller: _passwordController,
                              obscureText: isObscure,
                              cursorColor: Colors.white,

                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                    width: 0.8,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.blue,
                                    width: 0.8,
                                  ),
                                ),
                                labelText: " Password ",
                                labelStyle: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      isObscure = !isObscure;
                                    });
                                  },
                                  icon: Icon(
                                    isObscure
                                        ? Icons.lock
                                        : Icons
                                              .no_encryption_gmailerrorred_rounded,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setState(() {
                                      isRemember = !isRemember;
                                    });
                                    handleRememberMe();
                                  },
                                  icon: Icon(
                                    isRemember
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                  ),
                                ),
                                const Text(
                                  'Remember me',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 40),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: GestureDetector(
                onTap: () {
                  login();
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset('assets/icons/ic_button.png'),
                    Text(
                      "Log In",
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Don’t have an account?',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpPage(),
                      ),
                    );
                  },
                  child: Text(
                    "Sign Up",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> login() async {
    if (!isValidEmail(_emailController.text)) {
      Fluttertoast.showToast(
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        msg: "Please enter a valid email address",
      );
      return;
    }

    showCircularProgress(context);

    try {
      var url = Uri.parse(
        "https://securenet.justyes.co.uk/Prod/SwiftBooksApis/login.php",
      );

      http.Response? response;
      int maxRetries = 2; // Up to 2 retries (3 total attempts)

      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          response = await http.post(
            url,
            body: {
              "db_key": "R.kieZ",
              "username": _emailController.text.trim(),
              "password": _passwordController.text.trim(),
            },
          ).timeout(const Duration(seconds: 12));

          break; // Request succeeded, break out of retry loop
        } on HandshakeException catch (e) {
          if (attempt == maxRetries) rethrow; // Out of attempts, send to main catch block
          await Future.delayed(const Duration(milliseconds: 600)); // Short pause before retry
        } on SocketException catch (e) {
          if (attempt == maxRetries) rethrow;
          await Future.delayed(const Duration(milliseconds: 600));
        }
      }

      if (response == null) {
        if (mounted) Navigator.pop(context); // Close loading dialog
        return;
      }

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        if (isRemember) {
          await prefs.setString('email', _emailController.text.trim());
          await prefs.setString('password', _passwordController.text.trim());
          await prefs.setBool('remember', true);
        } else {
          await prefs.remove('email');
          await prefs.remove('password');
          await prefs.setBool('remember', false);
        }

        if (data['status'].toString() == "success") {
          if (!mounted) return;

          setState(() {
            clientEmail = _emailController.text.trim();
            lastName = data['LastName']?.toString() ?? "";
            phoneNumber = data['PhoneNumber']?.toString() ?? "";
            clientID = data['ClientID']?.toString() ?? "";
            businessName = data['BusinessName']?.toString() ?? "";
            accountantID = data['AccountantID']?.toString() ?? "";
            expiryDate = data['ExpiryDate']?.toString() ?? "";
          });

          // Dismiss the loading dialog
          Navigator.pop(context);

          // Check Accountant ID & Expiry
          if (accountantID.isEmpty) {
            _navigateToDashboard();
            return;
          }

          String expiryStatus = checkExpiryStatus(expiryDate);
          if (expiryStatus == "Your subscription is active") {
            _navigateToDashboard();
          } else {
            showExpiryDialog(context);
          }
        } else {
          if (mounted) Navigator.pop(context);
          Fluttertoast.showToast(
            backgroundColor: Colors.red,
            textColor: Colors.white,
            msg: 'Invalid username or password',
            toastLength: Toast.LENGTH_SHORT,
          );
        }
      } else {
        if (mounted) Navigator.pop(context);
        Fluttertoast.showToast(
          backgroundColor: Colors.red,
          textColor: Colors.white,
          msg: "Server error: ${response.statusCode}",
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      Fluttertoast.showToast(
        backgroundColor: Colors.red,
        textColor: Colors.white,
        msg: "Connection error: ${e is HandshakeException ? 'Secure connection lost, please try again.' : e.toString()}",
      );
    }
  }

// Helper method to keep dashboard navigation clean & DRY
  void _navigateToDashboard() {
    if (!mounted) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => DashBoard(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(seconds: 1),
      ),
    );
  }

  String checkExpiryStatus(String expiryDateString) {
    // Expected format: "dd-MM-yyyy"
    try {
      final dateParts = expiryDateString.split('-');
      if (dateParts.length != 3) {
        return "Invalid date format";
      }

      final expiryDate = DateTime(
        int.parse(dateParts[2]), // year
        int.parse(dateParts[1]), // month
        int.parse(dateParts[0]), // day
      );

      final currentDate = DateTime.now();

      if (currentDate.isAfter(expiryDate)) {
        return "Your subscription has expired.";
      } else if (currentDate.isAtSameMomentAs(expiryDate)) {
        return "Your subscription expires today.";
      } else {
        return "Your subscription is active";
      }
    } catch (e) {
      return "Error parsing date: $e";
    }
  }

  void showExpiryDialog(BuildContext context) {
    bool isDarkMode = themeNotifier.value == ThemeMode.dark;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.red : Colors.blue,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: const [
                    Text(
                      'Trial Version Expired',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your trial has ended. Unlock the full power of our accounting services by subscribing today!',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    TextButton(
                      onPressed: () async {
                        Fluttertoast.showToast(
                          msg: "Your trial has expired. Redirecting...",
                        );

                        final Uri url = Uri.parse(
                          "https://securenet.justyes.co.uk/UAT/SwiftBooksAI/login.php",
                        );

                        try {
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode
                                  .platformDefault,
                            );
                          } else {
                            // fallback if canLaunchUrl() returns false
                            await launchUrl(
                              url,
                              mode:
                                  LaunchMode.inAppWebView,
                            );
                          }
                        } catch (e) {
                          Fluttertoast.showToast(msg: "Error: $e");
                        }
                      },

                      child: const Text(
                        'Subscribe Now',
                        style: TextStyle(color: Colors.green, fontSize: 16),
                      ),
                    ),

                    Divider(
                      color: isDarkMode ? Colors.white12 : Colors.grey,
                      thickness: 1,
                    ),
                    TextButton(
                      onPressed: () {
                        if (Platform.isAndroid) {
                          SystemNavigator.pop();
                        } else if (Platform.isIOS) {
                          exit(0);
                        }
                      },
                      child: const Text(
                        'Exit App',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    return emailRegex.hasMatch(email);
  }

  // To show the dialog

  void handleRememberMe() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (isRemember) {
      await prefs.setString('email', _emailController.text.trim());
      await prefs.setString('password', _passwordController.text.trim());
      await prefs.setBool('remember', true);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.setBool('remember', false);
    }
  }

  void loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString('email');
    String? savedPassword = prefs.getString('password');
    bool? remember = prefs.getBool('remember');

    if (remember == true && savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        isRemember = true;
      });
    }
  }
}
