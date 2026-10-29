import 'dart:convert';
import 'package:edge_alerts/edge_alerts.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:swiftbook_ai/Global.dart';
import 'ReceiptImageViewerScreen.dart';

class MyReceiptsScreen extends StatefulWidget {
  const MyReceiptsScreen({super.key});

  @override
  State<MyReceiptsScreen> createState() => _MyReceiptsScreenState();
}

class _MyReceiptsScreenState extends State<MyReceiptsScreen> {
  List<Map<String, dynamic>> receipts = [];
  bool isLoading = true;

  late String receiptID;
  late String updatedImageURL;

  @override
  void initState() {
    super.initState();
    getReceiptDetails();
  }

  Future<void> getReceiptDetails() async {
    try {
      final response = await http.post(
        Uri.parse(
          "https://securenet.justyes.co.uk/Prod/SwiftBooksApis/receiptsJson.php",
        ),
        body: {"db_key": "R.kieZ", "clientID": clientID.toString()},
      );

      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          setState(() {
            receipts = data
                .where(
                  (receipt) =>
                      receipt["ClientID"].toString() == clientID.toString(),
                )
                .map<Map<String, dynamic>>(
                  (receipt) => Map<String, dynamic>.from(receipt),
                )
                .toList();

            isLoading = false;
          });
        } else {
          Fluttertoast.showToast(msg: "Invalid response from server");
          setState(() {
            isLoading = false;
          });
        }
      } else {
        Fluttertoast.showToast(msg: "Server Error: ${response.statusCode}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      // Fluttertoast.showToast(msg: "Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Receipts")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : receipts.isEmpty
          ? const Center(
              child: Text("No receipts found", style: TextStyle(fontSize: 17)),
            )
          : ListView.builder(
              itemCount: receipts.length,
              itemBuilder: (context, index) {
                final receipt = receipts[index];
                return Card(
                  color: const Color.fromARGB(40, 158, 158, 158),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),  Text(
                          "Issued By: ${receipt['ReceiptIssuedBy']}",
                          style: GoogleFonts.raleway(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),

                        Text(
                          "Customer ID: ${receipt['ClientID']}",
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          "Date: ${receipt['ReceiptDate']}",
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          "Transaction Type: ${receipt['TransactionType']}",
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          "Total Amount: £${receipt['AmountTotal']}",
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                if (!mounted) return;
                                //
                                // print(
                                //   "Images: " +
                                //       receipt['ImagePath'] +
                                //       receipt['ImageNames'],
                                // );

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReceiptImageViewerScreen(
                                      imageUrls:
                                          receipt['ImagePath'] +
                                          receipt['ImageNames'], // <-- updated
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),

                                backgroundColor: Colors.blue.shade600,
                              ),
                              icon: const Icon(
                                Icons.remove_red_eye,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "View Receipt",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            SizedBox(width: 10),

                            ElevatedButton.icon(
                              onPressed: () {
                                if (!mounted) return;

                                setState(() {
                                  receiptID = receipt['ReceiptID'];
                                  updatedImageURL =
                                      receipt['ImagePath'] +
                                      receipt['ImageNames'];
                                });

                                showDeleteReceiptDialog(context);
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor: Colors.red.shade800,
                              ),
                              icon: const Icon(
                                Icons.delete,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "Delete",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void showDeleteReceiptDialog(BuildContext context) {
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
                  color: Colors.red.shade800,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      "Delete",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Are your sure to delete?',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Container(
                color: Color.fromARGB(40, 158, 158, 158),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          deleteReceiptRecord(receiptID);
                        },
                        child: Text(
                          'Yes, Delete Now',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Divider(color: Colors.grey, thickness: 1),
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
              ),
            ],
          ),
        );
      },
    );
  }

  Future deleteReceiptRecord(String receiptID) async {
    try {
      showCircularProgress(context);
      var url = Uri.parse(
        "https://securenet.justyes.co.uk/Prod/SwiftBooksApis/deleteReceipt.php",
      );

      var response = await http.post(
        url,
        body: {"db_key": "R.kieZ",
          "receiptID": receiptID.trim()},
      );

      if (response.statusCode == 200) {
        print("Response: ${response.body}");
        var data = json.decode(response.body);

        if (data == "DELETED") {
          setState(() {
            receipts.removeWhere(
              (item) => item['ReceiptID'] == receiptID,
            );
          });
          _deleteReceiptImage(updatedImageURL);
          return;
        } else if (data == "NOT_FOUND") {
          edgeAlert(
            context,
            title: 'Receipt Not Found ' + receiptID,
            description: 'No receipt found.',
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
        debugPrint("HTTP error ${response.statusCode}: ${response.body}");
        Fluttertoast.showToast(msg: "Unexpected error occurred");
        Navigator.pop(context);
      }
    } catch (error) {
      Fluttertoast.showToast(msg: "Something went wrong");
      debugPrint("Error: $error");
      Navigator.pop(context);
    }
  }

  Future<bool> _deleteReceiptImage(String imageUrls) async {
    try {
      const apiUrl =
          'https://securenet.justyes.co.uk/Prod/SwiftBooksApis/deleteImage.php';

      final response = await http.post(
        Uri.parse(apiUrl),
        body: {"image_name": imageUrls},
      );

      // Dismiss loading dialog safely before context updates
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (response.statusCode != 200) {
        if (mounted) {
          _showSnackBar('Server Error: ${response.statusCode}', isError: true);
        }
        return false;
      }

      final responseJson = json.decode(response.body);

      if (responseJson['success'] == true) {
        if (mounted) {
          // _showSnackBar(
          //   responseJson['message'] ?? 'Images deleted successfully',
          // );
        }
        return true;
      } else {
        if (mounted) {
          _showSnackBar(
            responseJson['message'] ?? 'Failed to delete images',
            isError: true,
          );
        }
        return false;
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        _showSnackBar('Error: ${e.toString()}', isError: true);
      }
      return false;
    }
  }

  // Helper method for standard SnackBar notifications
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
