import 'dart:convert';
import 'dart:io';
import 'package:edge_alerts/edge_alerts.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:swiftbook_ai/Global.dart';

import 'login_page.dart';
import 'main.dart';

class MyProfileScreen extends StatefulWidget {
  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("My Profile", style: TextStyle(color: Colors.white)),
          automaticallyImplyLeading: true,
        ),
        backgroundColor: Colors.black54,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                _buildContactSection(
                  title: 'Client ID',
                  icon: Icons.badge,
                  iconColor: Colors.blue,
                  content: clientID,
                ),

                SizedBox(height: 5),

                _buildContactSection(
                  title: 'Name',
                  icon: Icons.person,
                  iconColor: Colors.deepOrangeAccent,
                  content: lastName,
                ),

                SizedBox(height: 5),

                _buildContactSection(
                  title: 'Email Address',
                  icon: Icons.email,
                  iconColor: Colors.yellow.shade800,
                  content: clientEmail,
                ),
                SizedBox(height: 5),
                _buildContactSection(
                  title: 'Contact',
                  icon: Icons.phone,
                  iconColor: Colors.green,
                  content: phoneNumber,
                ),


                SizedBox(height: 5),
                _buildContactSection(
                  title: 'Business Name',
                  icon: Icons.business,
                  iconColor: Colors.yellow,
                  content: businessName,
                ),
                SizedBox(height: 25),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                     showDeleteAccountDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800, // button background color
                      foregroundColor: Colors.white, // text & icon color
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // rounded corners
                      ),
                    ),
                    icon: const Icon(Icons.delete), // you can also use asset image here
                    label: const Text(
                      "Delete My Account",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )

              ],
            ),
          ),
        ),
      ),
    );
  }



  void showDeleteAccountDialog(BuildContext context) {
    final bool isDarkMode = themeNotifier.value == ThemeMode.dark;
    final double dialogWidth = MediaQuery.of(context).size.width * 0.85; // 85% of screen

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return SafeArea(
          child: Center(
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                width: dialogWidth,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.red : Colors.blue,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: const [
                          Text(
                            'Delete Account',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Are you sure to delete your account. Once deleted, you cannot log in using the same account',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              deleteAccount(clientEmail);
                            },
                            child: const Text(
                              'Yes, Delete My Account',
                              style: TextStyle(color: Colors.red, fontSize: 16),
                            ),
                          ),
                          Divider(
                            color: isDarkMode ? Colors.white12 : Colors.grey,
                            thickness: 1,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.green, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }



  Future deleteAccount(String email) async {
    try {
      showCircularProgress(context);

      var url = Uri.parse(
        "https://securenet.justyes.co.uk/Prod/SwiftBooksApis/deleteClient.php",
      );

      var response = await http.post(url, body: {"email": email.trim()});

      if (response.statusCode == 200) {
        print("Response: ${response.body}");
        var data = json.decode(response.body);

        if (data == "DELETED") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } else if (data == "NOT_FOUND") {
          edgeAlert(
            context,
            title: 'Account Not Found',
            description: 'No account found with this email.',
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
  void showCircularProgress(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      // Prevent the user from dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator(color: Colors.blueGrey));
      },
    );
  }

  showLogoutAlertDialog(BuildContext context, String title, String message) {
    Widget okbtn = TextButton(
      onPressed: () {
        if (Platform.isAndroid) {
          SystemNavigator.pop();
        } else if (Platform.isIOS) {
          exit(0);
        }
      },
      style: TextButton.styleFrom(backgroundColor: Colors.green),
      child: const Text("Yes", style: TextStyle(color: Colors.white)),
    );

    Widget cancelbtn = TextButton(
      child: Text("No", style: TextStyle(color: Colors.white)),
      onPressed: () {
        Navigator.pop(context);
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.deepOrange,
      ),
    );

    AlertDialog alert = AlertDialog(
      backgroundColor: Colors.black,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(fontSize: 20, color: Colors.white),
      ),
      actions: [cancelbtn, okbtn],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Widget _buildContactSection({
    required String title,
    required IconData icon,
    Color iconColor = Colors.grey,
    required String content,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28.0, color: iconColor),
          SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 5.0),
                if (onTap != null)
                  InkWell(
                    onTap: onTap,
                    child: Text(
                      content,
                      style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
                    ),
                  ),
                if (onTap == null)
                  InkWell(
                    child: Text(
                      content,
                      style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
