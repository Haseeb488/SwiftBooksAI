import 'dart:convert';
import 'dart:io';
import 'package:edge_alerts/edge_alerts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:swiftbook_ai/DashBoard.dart';
import 'package:swiftbook_ai/Global.dart';
import 'package:url_launcher/url_launcher.dart';

import 'main.dart';

class MyAccountantScreen extends StatefulWidget {
  @override
  State<MyAccountantScreen> createState() => _MyAccountantScreenState();
}

class _MyAccountantScreenState extends State<MyAccountantScreen> {
  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      showCircularProgress(context);

      final result = await getAccountantDetails(context);

      // Fluttertoast.showToast(msg: result!["message"].toString());

      if (result!["message"] == "Accountant Found") {
        setState(() {
          accountantID = result["accountantID"]!;
          accountantName = result["accountantName"]!;
          accountantPhone = result["accountantPhone"]!;
          accountantEmail = result["accountantEmail"]!;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (!didPop) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashBoard()),
            );
          }
        },

        child: Scaffold(
          appBar: AppBar(
            title: Text("My Accountant", style: TextStyle(color: Colors.white)),
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
                    title: 'Accountant ID',
                    icon: Icons.badge,
                    iconColor: Colors.blue,
                    content: accountantID,
                  ),

                  SizedBox(height: 5),

                  _buildContactSection(
                    title: 'Accountant Name',
                    icon: Icons.person,
                    iconColor: Colors.deepOrangeAccent,
                    content: accountantName,
                  ),

                  SizedBox(height: 5),
                  _buildContactSection(
                    title: 'Contact',
                    icon: Icons.phone,
                    iconColor: Colors.green,
                    content: accountantPhone,
                    onTap: () {
                      launchPhone(phoneNumber);
                    },
                  ),

                  SizedBox(height: 5),

                  _buildContactSection(
                    title: 'Email Address',
                    icon: Icons.email,
                    iconColor: Colors.yellow.shade800,
                    content: accountantEmail,

                    onTap: () async {
                      final Uri emailUri = Uri(
                        scheme: 'mailto',
                        path: clientEmail,
                        query: "subject=Invoice Inquiry", // optional
                      );

                      if (await canLaunchUrl(emailUri)) {
                        await launchUrl(emailUri);
                      } else {
                        print("Could not open email client");
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<Map<String, String>?> getAccountantDetails(
    BuildContext context,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          "https://securenet.justyes.co.uk/Prod/SwiftBooksApis/accountantJson.php",
        ),
        body: {"db_key": "R.kieZ"},
      );

      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");
      print("Accountant ID: $accountantID");

      if (response.statusCode == 200) {
        hideCircularProgress(context);

        final data = json.decode(response.body);

        if (accountantID.toString().isEmpty) {
          showRegisterAccountantDialog(context);
          return {"message": "Accountant not available"};
        }

        if (data is List && data.isNotEmpty) {
          final matchedAccountant = data.firstWhere(
            (acc) => acc["AccountantID"].toString() == accountantID.toString(),
            orElse: () => <String, dynamic>{},
          );

          if (matchedAccountant.isNotEmpty) {
            return {
              "message": "Accountant Found",
              "accountantID":
                  matchedAccountant["AccountantID"]?.toString() ?? "",
              "accountantName":
                  matchedAccountant["AccountantName"]?.toString() ?? "",
              "accountantEmail": matchedAccountant["Email"]?.toString() ?? "",
              "accountantPhone":
                  matchedAccountant["PhoneNumber"]?.toString() ?? "",
            };
          } else {
            return {"message": "Accountant not found with this ID"};
          }
        } else {
          return {"message": "No accountants found"};
        }
      } else {
        hideCircularProgress(context);
        return {"message": "Server Error: ${response.statusCode}"};
      }
    } catch (e) {
      hideCircularProgress(context);
      print("Error: $e");
      return {"message": "Error: $e"};
    }
  }

  void showRegisterAccountantDialog(BuildContext context) {
    final bool isDarkMode = themeNotifier.value == ThemeMode.dark;
    final double dialogWidth = MediaQuery.of(context).size.width * 0.85;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
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
                            'Accountant Not Found',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Do you want to register with an accountant?',
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
                              Navigator.pop(context);
                              showAccountantFormDialog(context, isDarkMode);
                            },
                            child: const Text(
                              'Yes, Register Now',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Divider(
                            color: isDarkMode ? Colors.white12 : Colors.grey,
                            thickness: 1,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DashBoard(),
                                ),
                              );
                            },
                            child: const Text(
                              'Not Now',
                              style: TextStyle(color: Colors.red, fontSize: 16),
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

  void showAccountantFormDialog(BuildContext context, bool isDarkMode) {
    final TextEditingController idController = TextEditingController();
    final double dialogWidth = MediaQuery.of(context).size.width * 0.85;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
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
                      child: const Text(
                        'Register Accountant',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Form
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: idController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: "Accountant ID",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    // Buttons
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.red, fontSize: 16),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              FocusScope.of(context).unfocus(); // hide keyboard

                              if (idController.text.isEmpty) {
                                edgeAlert(
                                  context,
                                  title: 'Account ID is Required',
                                  description: 'Please enter accountant ID',
                                  gravity: Gravity.bottom,
                                  duration: 1,
                                  icon: Icons.warning,
                                  backgroundColor: Colors.blue,
                                );
                                return;
                              }

                              showCircularProgress(context);
                              accountantID = idController.text.trim();

                              // TODO: send `name` & `id` to API here
                              print("Accountant Name: $accountantName");
                              print("Accountant ID: $accountantID");

                              Map<String, String>? accountantStatus =
                                  await getAccountantDetails(context);

                              print("Response ${accountantStatus!["message"]}");

                              if (accountantStatus["message"].toString() ==
                                  "Accountant not found with this ID") {
                                Fluttertoast.showToast(
                                  msg: accountantStatus["message"].toString(),
                                );
                                accountantID = "";
                                return;
                              }

                              if (accountantStatus["message"].toString() ==
                                  "Accountant Found") {
                                String result = await updateAccountant(
                                  email: clientEmail,
                                  accountantID: accountantID,
                                  days: 30,
                                );

                                // --- Extract the message value ---
                                String messageValue = "";

                                RegExp regExp = RegExp(r'message:\s*([^}]+)');
                                Match? match = regExp.firstMatch(result);

                                if (match != null) {
                                  // Extract the text captured inside the parentheses and trim any extra spaces
                                  messageValue = match.group(1)!.trim();
                                }

                                print(
                                  "The extracted message is: $messageValue",
                                );

                                if (messageValue == "UPDATED") {
                                  Navigator.pop(context);

                                  setState(() {
                                    // 3. Store the details into individual String variables
                                    accountantID =
                                        accountantStatus["accountantID"] ?? "";
                                    accountantName =
                                        accountantStatus["accountantName"] ??
                                        "";
                                    accountantEmail =
                                        accountantStatus["accountantEmail"] ??
                                        "";
                                    accountantPhone =
                                        accountantStatus["accountantPhone"] ??
                                        "";
                                  });
                                }
                              }
                            },
                            child: const Text(
                              'Submit',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 16,
                              ),
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

  Future<String> updateAccountant({
    required String email,
    required String accountantID,
    required int days, // 👈 new parameter
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          "https://securenet.justyes.co.uk/Prod/SwiftBooksApis/updateAccountant.php",
        ),
        body: {
          "db_key": "R.kieZ",
          "email": email,
          "accountantID": accountantID,
          "days": days.toString(),
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result == "UPDATED") {
          return "Accountant updated successfully";
        } else if (result == "NO_CHANGE") {
          return "No changes made";
        } else if (result == "NOT_FOUND") {
          return "Client not found";
        } else {
          return "Error: $result";
        }
      } else {
        return "Server error: ${response.statusCode}";
      }
    } catch (e) {
      return "Exception: $e";
    }
  }

  Future<void> launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber, // e.g. "03001234567"
    );

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      print("Could not open dialer");
    }
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
